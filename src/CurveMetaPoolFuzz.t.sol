pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./CurveMetaPoolFuzz.sol";

contract CurveMetaPoolFuzzTest is DSTest {
    CurveMetaPoolFuzz fuzz;

    function setUp() public {
        fuzz = new CurveMetaPoolFuzz();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
