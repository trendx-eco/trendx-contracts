// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/uniswapV2/IUniswapFactory.sol";
import "../interfaces/uniswapV2/IUniswapPair.sol";
import "../interfaces/uniswapV2/IUniswapRouter02.sol";

contract UniSwapV2 {
    using SafeERC20 for IERC20;
    address public router;

    constructor(address _router) {
        router = _router;
    }

    function autoSwapTokens(
        address token0,
        uint256 amountIn,
        address to,
        uint256 amountOutMin,
        address[] calldata path
    ) internal {
        IERC20(token0).safeApprove(router, amountIn);
        IUniswapRouter02(router)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOutMin,
                path,
                to,
                block.timestamp + 600
            );
    }

    function autoSwapEthToTokens(
        uint256 amountIn,
        address to,
        uint256 amountOutMin,
        address[] calldata path
    ) internal {
        // make the swap
        IUniswapRouter02(router)
            .swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amountIn
        }((amountOutMin * 9) / 10, path, to, block.timestamp + 600);
    }

    function getAmountOuts(
        uint256 _amountIn,
        address[] calldata _path
    ) public view returns (uint256) {
        //Calculate the quantity of this purchase
        return IUniswapRouter02(router).getAmountsOut(_amountIn, _path)[1];
    }
}
