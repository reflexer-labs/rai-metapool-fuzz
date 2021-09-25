pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./RaiMetaPoolFuzz.sol";

contract RaiMetaPoolFuzzTest is DSTest {
    RaiMetaPoolFuzz fuzz;

    function setUp() public {
        fuzz = new RaiMetaPoolFuzz();
    }

    function test_basic_sanity() public {
        fuzz.swap(true, 30 ether);
    }
}