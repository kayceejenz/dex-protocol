// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IFactory.sol"; 

contract Pair is ERC20 {
    address public immutable factory;
    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint private kLast; // reserve0 * reserve1, used for fee-on logic

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amountIn0, uint amountIn1, uint amountOut0, uint amountOut1, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    constructor(address _factory) ERC20("DEX LP Token", "DLP") {
        factory = _factory;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "DEX: FORBIDDEN");
        require(token0 == address(0) && token1 == address(0), "Already initialized");
        token0 = _token0;
        token1 = _token1;
    }

    function getReserves() public view returns (uint112, uint112) {
        return (reserve0, reserve1);
    }

    function _update(uint balance0, uint balance1) private {
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);
        emit Sync(reserve0, reserve1);

        if (IERC20(token0).balanceOf(address(this)) > 0 && IERC20(token1).balanceOf(address(this)) > 0) {
            kLast = uint(reserve0) * uint(reserve1);
        }
    }

    function _mintFee(uint _reserve0, uint _reserve1) private {
        address feeTo = IFactory(factory).treasury();
        if (feeTo == address(0)) return;

        if (kLast != 0) {
            uint rootK = Math.sqrt(_reserve0 * _reserve1);
            uint rootKLast = Math.sqrt(kLast);
            if (rootK > rootKLast) {
                uint numerator = totalSupply() * (rootK - rootKLast);
                uint denominator = (rootK * 5) + rootKLast;
                uint liquidity = numerator / denominator;
                if (liquidity > 0) {
                    _mint(feeTo, liquidity);
                }
            }
        }
    }

    function mint(uint amount0, uint amount1, address sender) external returns (uint liquidity) {
        IERC20(token0).transferFrom(sender, address(this), amount0);
        IERC20(token1).transferFrom(sender, address(this), amount1);

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        _mintFee(_reserve0, _reserve1);

        uint _totalSupply = totalSupply();

        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1);
        } else {
            liquidity = Math.min(
                (amount0 * _totalSupply) / _reserve0,
                (amount1 * _totalSupply) / _reserve1
            );
        }

        require(liquidity > 0, "Insufficient liquidity minted");
        _mint(sender, liquidity);

        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));

        emit Mint(sender, amount0, amount1);
    }

    function burn(uint liquidity, address sender) external returns (uint amount0, uint amount1) {
        require(balanceOf(sender) >= liquidity, "Not enough LP tokens");

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        _mintFee(_reserve0, _reserve1);

        uint _totalSupply = totalSupply();
        amount0 = (liquidity * _reserve0) / _totalSupply;
        amount1 = (liquidity * _reserve1) / _totalSupply;

        _burn(sender, liquidity);

        IERC20(token0).transfer(sender, amount0);
        IERC20(token1).transfer(sender, amount1);

        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));

        emit Burn(sender, amount0, amount1, sender);
    }

    function swap(uint amountIn0, uint amountIn1, address to) external {
        require(amountIn0 == 0 || amountIn1 == 0, "Only one token can be swapped in");
        require(amountIn0 != 0 || amountIn1 != 0, "Insufficient input");

        (uint112 _reserve0, uint112 _reserve1) = getReserves();
        _mintFee(_reserve0, _reserve1);

        if (amountIn0 > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amountIn0);

            uint amountOut1 = getAmountOut(amountIn0, _reserve0, _reserve1);
            require(amountOut1 < _reserve1, "Not enough liquidity");
            IERC20(token1).transfer(to, amountOut1);

            emit Swap(msg.sender, amountIn0, 0, 0, amountOut1, to);
        }

        if (amountIn1 > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amountIn1);

            uint amountOut0 = getAmountOut(amountIn1, _reserve1, _reserve0);
            require(amountOut0 < _reserve0, "Not enough liquidity");
            IERC20(token0).transfer(to, amountOut0);

            emit Swap(msg.sender, 0, amountIn1, amountOut0, 0, to);
        }

        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)));
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint) {
        require(amountIn > 0, "Insufficient input amount");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = (reserveIn * 1000) + amountInWithFee;
        return numerator / denominator;
    }
}
