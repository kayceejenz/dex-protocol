// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interfaces/IPair.sol";
import "./Pair.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract Factory {
    using Clones for address;

    address public admin;
    address public treasury;
    address public pairImplementation;

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    constructor(address _admin, address _pairImplementation) {
        require(_pairImplementation != address(0), "DEX: INVALID_IMPLEMENTATION");
        admin = _admin;
        pairImplementation = _pairImplementation;
    }

    function allPairsLength() external view returns (uint) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "DEX: IDENTICAL_ADDRESSES");

        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        require(token0 != address(0), "DEX: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "DEX: PAIR_EXISTS");

        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        pair = pairImplementation.cloneDeterministic(salt);

        IPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair;

        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function getPairAddress(address tokenA, address tokenB) external view returns (address predicted) {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        predicted = pairImplementation.predictDeterministicAddress(salt, address(this));
    }

    function setTreasury(address _treasury) external {
        require(msg.sender == admin, "DEX: FORBIDDEN");
        treasury = _treasury;
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin, "DEX: FORBIDDEN");
        admin = _admin;
    }

    function setPairImplementation(address _impl) external {
        require(msg.sender == admin, "DEX: FORBIDDEN");
        pairImplementation = _impl;
    }
}
