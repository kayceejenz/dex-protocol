// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IPair.sol";
import "../interfaces/IRouter.sol";

contract Router is IRouter {
    using SafeERC20 for IERC20;

    address public immutable factory;

    constructor(address _factory) {
        factory = _factory;
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) external override {
        address pair = IFactory(factory).getPair(tokenA, tokenB);

        if (pair == address(0)) {
            pair = IFactory(factory).createPair(tokenA, tokenB);
        }

        IERC20(tokenA).safeTransferFrom(msg.sender, pair, amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, pair, amountB);

        IPair(pair).mint(msg.sender);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB
    ) external override {
        address pair = IFactory(factory).getPair(tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");

        uint lpBalance = IERC20(pair).balanceOf(msg.sender);
        require(lpBalance > 0, "No liquidity to remove");

        IERC20(pair).safeTransferFrom(msg.sender, pair, lpBalance);
        IPair(pair).burn(msg.sender);
    }

    function swapExactTokensForTokens(
        uint amountIn,
        address[] calldata path,
        address to
    ) external override {
        require(path.length >= 2, "Invalid path");

        IERC20(path[0]).safeTransferFrom(msg.sender, _pairFor(path[0], path[1]), amountIn);
        _swap(path, to);
    }

    function _pairFor(address tokenA, address tokenB) internal view returns (address) {
        return IFactory(factory).getPair(tokenA, tokenB);
    }

    function _swap(address[] memory path, address to) internal {
        for (uint i = 0; i < path.length - 1; i++) {
            address input = path[i];
            address output = path[i + 1];
            address pair = _pairFor(input, output);

            address recipient = i < path.length - 2 ? _pairFor(output, path[i + 2]) : to;

            IPair(pair).swap(input, output, recipient);
        }
    }
}
