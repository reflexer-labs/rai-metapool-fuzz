pragma solidity ^0.6.7;

import "./token.sol";
import "./Bytecodes.sol";
import "./RedemptionPriceSnapMock.sol";

abstract contract RAIPoolLike {
    function initialize(string calldata, string calldata, address, uint, uint, uint, address, address, address, address, address) external virtual;
    function initialize_rate_feed(address, uint) external virtual;
    function initialize_fuzz() external virtual;
    function add_liquidity(uint[2] calldata, uint, address) external virtual returns (uint);
    function exchange(int128, int128, uint, uint, address) external virtual returns (uint);
    function ramp_A(uint, uint) external virtual;
    function fee() external view virtual returns (uint);
    function redemption_price_snap() external view virtual returns (address);
    function deployer() external view virtual returns (address);
    function coins(uint) external view virtual returns(address);
}

abstract contract _3poolLike {
    function initialize(address, address[3] calldata, address, uint, uint, uint) external virtual;
    function add_liquidity(uint[3] calldata, uint) external virtual;
    function exchange(int128, int128, uint, uint) external virtual returns (uint);
    function ramp_A(uint, uint) external virtual;
}

contract User {
    RAIPoolLike raiPool;

    constructor(RAIPoolLike pool) public {
        raiPool = pool;
        DSToken(raiPool.coins(0)).approve(address(raiPool), uint(-1));
        DSToken(raiPool.coins(1)).approve(address(raiPool), uint(-1));
    }

    function swap(int128 _i, int128 _j, uint _dx) public returns (uint) {
        return raiPool.exchange(_i, _j, _dx, 0, address(this));
    }
}

contract RaiMetaPoolFuzz is Bytecodes {
    mapping (address => User) users;
    // tokens
    DSToken rai;
    DSToken dai;
    DSToken usdc;
    DSToken usdt;
    DSToken _3poolToken;

    // pools
    _3poolLike _3pool;
    RAIPoolLike raiMetaPool;

    // redemption price feed
    RedemptionPriceSnapMock redemptionPriceSnap;

    // params
    // Amplification factor (RAI meta pool)
    uint A = 100;
    // Redemption price deviation
    uint redemptionPriceDeviation = 20;     // 20 == 2%
    // Accepted slippage, swaps with more than the expected slippage will be flagged as failures by the fuzzer
    uint acceptedSlippage = 10;             // 10 == 1%
    // Initial RAI liquidity, 3pool will have 10x more liquidity, and the RAI pool will be seeded proportionally (~3 3pool per RAI)
    uint initialRaiLiquidity = 166000 ether; // around 500k, the minimum for listing on Curve's FE

    constructor() public {
        // deploy tokens
        rai  = new DSToken("RAI", "RAI", 18);
        dai  = new DSToken("DAI", "DAI", 18);
        usdc = new DSToken("USDC", "USDC", 6);
        usdt = new DSToken("USDT", "USDT", 6);
        _3poolToken = new DSToken("3pool", "3pool", 18);

        // deploy 3pool
        _3pool = _3poolLike(create(_3poolBytecode));
        _3pool.initialize(
            address(1),                                   // owner
            [address(dai), address(usdc), address(usdt)], // coins
            address(_3poolToken),                         // pool token
            2000,                                         // A
            3000000,                                      // fee
            5000000000                                    // admin fee
        );
        _3poolToken.addAuthorization(address(_3pool));

        // add initial liquidity
        dai.mint(address(this), uint(30000000 ether));
        usdc.mint(address(this), uint(30000000 * 10**6));
        usdt.mint(address(this), uint(30000000 * 10**6));
        dai.approve(address(_3pool), uint(-1));
        usdc.approve(address(_3pool), uint(-1));
        usdt.approve(address(_3pool), uint(-1));
        _3pool.add_liquidity(
            [uint(30000000 ether), uint(30000000 * 10**6), uint(30000000 * 10**6)],
            0
        );

        // deploy redemption price feed
        redemptionPriceSnap = new RedemptionPriceSnapMock();

        // deploy Rai meta pool
        raiMetaPool = RAIPoolLike(create(RaiMetaPoolBytecode));

        raiMetaPool.initialize(
            "RAI 3pool",      // name
            "RAI3pool",       // symbol
            address(rai),     // coin address
            1,                // rate multiplier (not used)
            A,                // A
            4000000,          // fee
            address(_3pool),
            address(dai),
            address(usdc),
            address(usdt),
            address(_3poolToken)
        );

        raiMetaPool.initialize_rate_feed(
            address(redemptionPriceSnap),
            1000000000 // scale down from RAY to WAD
        );

        // add liquidity to Rai meta pool
        rai.mint(address(this), initialRaiLiquidity);
        rai.approve(address(raiMetaPool), initialRaiLiquidity);
        _3poolToken.approve(address(raiMetaPool), initialRaiLiquidity * 3);
        raiMetaPool.add_liquidity(
            [initialRaiLiquidity, initialRaiLiquidity * 3],
            0,
            address(this)
        );
    }

    function create(bytes memory bytecode) internal returns (address addr) {
        uint size = bytecode.length;

        assembly{
            addr := create(0, add(bytecode, 0x20), size)
            size := extcodesize(addr)
        }
        require(addr != address(0) && size > 0, "create failed");
    }

    // modifier that creates users for callers (setup no. of callers in echidna.yaml)
    modifier createUser {
        if (address(users[msg.sender]) == address(0)) {
            users[msg.sender] = new User(raiMetaPool);
            _3poolToken.approve(address(users[msg.sender]), uint(-1));
            rai.approve(address(users[msg.sender]), uint(-1));
        }
        _;
    }

    // swap
    function swap(bool rai3pool, uint amount) public createUser {
        User usr = users[msg.sender];
        uint dy = usr.swap(
            rai3pool ? 0 : 1,
            rai3pool ? 1 : 0,
            amount
        );
        // assert within slippage tollerance

    }

    // fuzz redemption price


    // properties


}
