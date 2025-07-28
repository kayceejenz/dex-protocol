// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountA,
        uint amountB
    ) external;

    function removeLiquidity(
        address tokenA,
        address tokenB
    ) external;

    function swapExactTokensForTokens(
        uint amountIn,
        address[] calldata path,
        address to
    ) external;
}
