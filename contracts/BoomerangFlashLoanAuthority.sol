// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {FlashLoanSimpleReceiverBase} from "@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@aave/core-v3/contracts/dependencies/openzeppelin/contracts/IERC20.sol";



interface IController {
    struct ProfitParams {
        address tokenAddress;
        address userAddress;
        uint256 profitAmount;
        uint256 profitUSD;
        uint256 borrowedValueinUSD;
    }
    function transferProfit(ProfitParams memory params) external returns(bool);
    function checkUserRole(address account) external view returns (bool);
    function checkADMINRole(address account) external view returns (bool);
}

interface IuniswapV3 {

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IV2SwapRouter {

    struct SushiswapParams {
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 limitSqrtPrice;
    }

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function exactInputSingle(SushiswapParams calldata params) external payable returns (uint256 amountOut);


}



contract FarziFlashLoanAuthorityV2 is FlashLoanSimpleReceiverBase {

    event FUNDTransferred(address account, uint256 amount);
    event SignControllerchanged(address prevSigner, address newSigner);
    event FarziControllerchanged(address prevController, address newController);

    //@notice Signer the event is emited at the time of changeSigner function invoke. 
    //@param previousSigner address of the previous contract owner.
    //@param newSigner address of the new contract owner.

    event SignerChanged(
        address signer,
        address newOwner
    );

    //@notice Sign struct stores the sign bytes
    //@param v it holds(129-130) from sign value length always 27/28.
    //@param r it holds(0-66) from sign value length.
    //@param s it holds(67-128) from sign value length.
    //@param nonce unique value.

    struct Sign{
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 nonce;
    }

    enum dexList {
        uniswapV2,
        uniswapV3,
        paraswap,
        quickwap
    }

    uint8[] dexPath;
    address[] pairs;
    address[] currentpairs;

    address sushiSwapAddress;
    address uniswapv3Address;
    address qucikswapAddress;

    address public FarziController;

    address public signController;

    mapping (bytes32 => bool) public isValidSign;


    modifier onlyUSERRole() {
        require(IController(FarziController).checkUserRole(msg.sender), "FarziFlashController: account not whitelisted");
        _;
    }

    modifier onlyADMINRole() {
        require(IController(FarziController).checkADMINRole(msg.sender), "FarziFlashController: invalid ADMIN account");
        _;
    }

    constructor(address _addressProvider, address _uniswapv3Address,address _quickswapAddress, address _sushiswapAddress, address _farziController, address _signer) 
        FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_addressProvider))
    {
       FarziController = _farziController;
       uniswapv3Address = _uniswapv3Address;
       qucikswapAddress = _quickswapAddress;
       sushiSwapAddress = _sushiswapAddress;
       signController = _signer;
    }

    function changeSignController(address newSigner) external onlyADMINRole() {
        require(newSigner != address(0), "Invalid signer address");
        address temp = signController;
        signController = newSigner;
        emit SignControllerchanged(temp, newSigner);
    }

    function changeFarziController(address newFarziController) external onlyADMINRole() {
        require(newFarziController != address(0), "Invalid signer address");
        address temp = FarziController;
        FarziController = newFarziController;
        emit FarziControllerchanged(temp, FarziController);
    }

    function withdrawFunds(address token, uint256 amount) external  onlyADMINRole() returns(bool) {
        require(amount !=0, "FarziController: amount should be greater than zero");
        bool status = IERC20(token).transfer(msg.sender, amount);
        emit FUNDTransferred(token, amount);
        return  status;
    }

    function swapTokens(uint256 amount, uint256 premium) internal {
        require((pairs.length) - 1 == dexPath.length, "invalid trx");

        uint256 borrowed = amount;

        for (uint i = 0; i < dexPath.length; i++)
        {

            if(dexList(dexPath[i]) == dexList.uniswapV3) {
                amount = uniswapV3(pairs[i], pairs[i+1], amount);
            }

            if(dexList(dexPath[i]) == dexList.paraswap) {
                amount = uniswapV3(pairs[i], pairs[i+1], amount);
            }
            
            if(dexList(dexPath[i]) == dexList.quickwap) {
                amount = quickSwap(pairs[i], pairs[i+1], amount);
            }
        }

        uint256 slippage = (borrowed - amount);
        require(slippage <= ((borrowed * 25)/1000), "Non-executable trade");
    }

    function uniswapV3(address tokenIn, address tokenOut, uint256 amount) internal returns(uint256) {

        IERC20(tokenIn).approve(uniswapv3Address, amount);
        IuniswapV3.ExactInputSingleParams memory params =
            IuniswapV3.ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: 3000,
                recipient: address(this),
                deadline: block.timestamp + 86400,
                amountIn: amount,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        uint256 amountOut = IuniswapV3(uniswapv3Address).exactInputSingle(params);
        return amountOut;

    }

    function sushiswap(address tokenIn, address tokenOut, uint256 amount) internal  returns(uint256[] memory) {
        IERC20(tokenIn).approve(sushiSwapAddress, amount);
        address[] memory pair = new address[](2);
        pair[1] = tokenIn;
        pair[2] = tokenOut; 
        uint256[] memory  amounts = IV2SwapRouter(sushiSwapAddress).swapTokensForExactTokens(
                amount,
                0,
                pair,
                address(this),
                block.timestamp + 86400
            );
        return amounts;
        
    }

    function quickSwap(address tokenIn, address tokenOut, uint256 amount) internal returns(uint256){
        IERC20(tokenIn).approve(qucikswapAddress, amount);
        IV2SwapRouter.SushiswapParams memory params =
            IV2SwapRouter.SushiswapParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                recipient: address(this),
                deadline: block.timestamp + 86400,
                amountIn: amount,
                amountOutMinimum: 0,
                limitSqrtPrice: 0
            });

        uint256 amountOut = IV2SwapRouter(qucikswapAddress).exactInputSingle(params);
        return amountOut;
        
    }

    /**
        This function is called after your contract has received the flash loaned amount
     */
    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        swapTokens(amount, premium);
        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);
        return true;
    }

    function requestFlashLoan(address _token, uint256 _amount, uint8[] memory _dexList, address[] memory _pairs, uint256 profit, uint256 borrowedAmountinUSD, uint256 profitinUSD, Sign calldata sign) public onlyUSERRole() {
        // verifySign(msg.sender, _token, _amount,sign);
        address receiverAddress = address(this);
        address asset = _token;
        uint256 amount = _amount;
        bytes memory params = "";
        uint16 referralCode = 0;
        dexPath = _dexList;
        pairs = _pairs;
        POOL.flashLoanSimple(
            receiverAddress,
            asset,
            amount,
            params,
            referralCode
        );

        if(profit > 0){
        IERC20(_token).transfer(FarziController, profit);
        IController.ProfitParams memory _params = IController.ProfitParams(_token, msg.sender, profit, profitinUSD,borrowedAmountinUSD);
        IController(FarziController).transferProfit(_params);
        }
    }

    function verifySign(
        address account,
        address bToken,
        uint256 amount,
        Sign memory sign
    ) public  {
        bytes32 hash = keccak256(
            abi.encodePacked(this, account, bToken, amount,sign.nonce)
        );

        require(
            !isValidSign[hash],
            "Duplicate Sign"
        );

        isValidSign[hash] = true;

        require(
            signController ==
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    sign.v,
                    sign.r,
                    sign.s
                ),
            "Signer sign verification failed"
        );

    }

    receive() external payable {}

    function withdraw(uint256 amount) external onlyADMINRole() {
        require(amount !=0, "FarziController: amount should be greater than zero");
        payable(msg.sender).transfer(amount);
    }
}