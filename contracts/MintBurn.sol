// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IMintBurn {
    function burn(address from, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external returns (bool);
}

contract MintBurn is IMintBurn, Ownable {
    event OperatorChanged(address indexed, bool);
    error NotAllowedOperator();

    mapping(address => bool) public operators;

    IMintBurn immutable public token;

    modifier onlyOperators() {
        if (!operators[msg.sender]) {
            revert NotAllowedOperator();
        }
        _;
    }

    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorChanged(operator, status);
    }

    constructor (IMintBurn token_) {
        token = token_;
    }
    function burn(address from, uint256 amount) external onlyOperators override returns (bool) {
        token.burn(from, amount);
    }
    function mint(address to, uint256 amount) external onlyOperators override returns (bool) {
        token.mint(to, amount);
    }

    function exec(address target, bytes calldata data) external onlyOwner {
        (bool success, bytes memory result) = target.call(data);
        if (!success) { // If call reverts
            // If there is return data, the call reverted without a reason or a custom error.
            if (result.length == 0) revert();
            assembly {
                // We use Yul's revert() to bubble up errors from the target contract.
                revert(add(32, result), mload(result))
            }
        }
    }
}
