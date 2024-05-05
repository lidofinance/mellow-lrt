// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../../src/interfaces/external/chainlink/IAggregatorV3.sol";
import "../../../src/libraries/external/FullMath.sol";

contract AggregatorV3WstethMock is IAggregatorV3 {
    address public immutable wsteth;
    IAggregatorV3 public immutable steth_oracle;
    uint256 internal constant steth_decimals = 18;
    bytes4 public constant TOKENS_PER_STETH_SELECTOR = 0x9576a0c8;

    function testMock() external {}

    constructor(address wsteth_, IAggregatorV3 steth_oracle_) {
        wsteth = wsteth_;
        steth_oracle = steth_oracle_;
    }

    function decimals() external view returns (uint8) {
        return steth_oracle.decimals();
    }

    function description() external pure returns (string memory) {
        return "WSTETH / USD";
    }

    function version() external view returns (uint256) {
        return steth_oracle.version();
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        pure
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {}

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = steth_oracle
            .latestRoundData();
        answer = _stethToWsteth(answer);
    }

    function _stethToWsteth(int256 amount) internal view returns (int256) {
        (bool res, bytes memory data) = wsteth.staticcall(
            abi.encodePacked(TOKENS_PER_STETH_SELECTOR)
        );
        if (!res) {
            assembly {
                let returndata_size := mload(data)
                revert(add(32, data), returndata_size)
            }
        }
        uint256 tokensPerStEth = abi.decode(data, (uint256));
        return
            int256(
                FullMath.mulDiv(
                    uint256(amount),
                    10 ** steth_decimals,
                    tokensPerStEth
                )
            );
    }
}