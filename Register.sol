//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

contract owned {
    constructor() { owner = payable(msg.sender); }
    address payable owner;
    // This contract only defines a modifier but does not use
    // it: it will be used in derived contracts.
    // The function body is inserted where the special symbol
    // `_;` in the definition of a modifier appears.
    // This means that if the owner calls this function, the
    // function is executed and otherwise, an exception is
    // thrown.
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }
}


contract destructible is owned {
    // This contract inherits the `onlyOwner` modifier from
    // `owned` and applies it to the `destroy` function, which
    // causes that calls to `destroy` only have an effect if
    // they are made by the stored owner.
    function destroy() public onlyOwner {
    selfdestruct(owner);
    }
}

contract priced {
    // Modifiers can receive arguments:
    modifier costs(uint price) {
        if (msg.value >= price) {
            _;
        }
    }
}
contract Register is priced, destructible {
mapping (address => bool) registeredAddresses;
uint price;
constructor(uint initialPrice) { price = initialPrice; }
// It is important to also provide the
// `payable` keyword here, otherwise the function will
// automatically reject all Ether sent to it.
function register() public payable costs(price) {
    registeredAddresses[msg.sender] = true;
}
function changePrice(uint _price) public onlyOwner {
    price = _price;
}
}