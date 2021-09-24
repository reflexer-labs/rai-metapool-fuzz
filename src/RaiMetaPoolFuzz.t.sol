pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./RaiMetaPoolFuzz.sol";

contract RaiMetaPoolFuzzTest is DSTest {
    RaiMetaPoolFuzz pool;

    function setUp() public {
        pool = new RaiMetaPoolFuzz();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
