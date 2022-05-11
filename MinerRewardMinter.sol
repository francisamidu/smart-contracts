// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MinerRewardMinter is ERC20 {
    ERC20Mintable _token;

    constructor(ERC20Mintable token) public {
        _token = token;
    }

    function _mintMinerReward() internal {
        _mint(block.coinbase, 1000);
    }

    function _transfer(address from, address to, uint256 value) internal {
        _mintMinerReward();
        super._transfer(from, to, value);
    }

}