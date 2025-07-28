// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

interface IPair {
    function initialize(address _token0, address _token1) external;

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(
        address input,
        address output,
        address to
    ) external;
}
