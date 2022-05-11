// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin/contracts/crowdsale/Crowdsale.sol";
import "openzeppelin/contracts/crowdsale/CappedCrowdsale.sol";
import "openzeppelin/contracts/crowdsale/TimeCrowdsale.sol";
import "openzeppelin/contracts/crowdsale/PostDeliveryCrowdsale.sol";
import "openzeppelin/contracts/crowdsale/RefundableCrowdsale.sol";
import "openzeppelin/contracts/crowdsale/MintedCrowdsale.sol";
import "openzeppelin/contracts/crowdsale/WhitelistCrowdsale.sol";


contract MyCrowdsale is Crowdsale, 
						CappedCrowdsale, 
						TimedCrowdsale, 
						PostDeliveryCrowdsale, 
						RefundableCrowdsale,
						WhitelistCrowdsale,
						MintedCrowdsale {

    constructor(
        uint256 rate,            // rate, in TKNbits
        address payable wallet,  // wallet to send Ether
        IERC20 token,            // the token
        uint256 cap,             // total cap, in wei
        uint256 openingTime,     // opening time in unix epoch seconds
        uint256 closingTime      // closing time in unix epoch seconds
        uint256 goal			 // the minimum goal in wei
		address[] users        
    )
        CappedCrowdsale(cap)
        Crowdsale(rate, wallet, token)
    	MintedCrowdsale()
        PostDeliveryCrowdsale()
    	RefundableCrowdsale()
        TimedCrowdsale(openingTime, closingTime)
        WhitelistCrowdsale(users)
        public
    {
        // nice, we just created a crowdsale that's only open
        // for a certain amount of time
        // and stops accepting contributions once it reaches `cap`
    }
}