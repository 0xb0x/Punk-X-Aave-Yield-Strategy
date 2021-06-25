// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ModelInterface.sol";
import "../ModelStorage.sol";
import "../3rdDeFiInterfaces/ILendingPool.sol";
import "../3rdDeFiInterfaces/IUniswapV2Router.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/IAaveIncentivesController.sol";

contract AaveModel is ModelInterface, ModelStorage{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address tokenInvestedIn; 
    address uRouterV2;
    ILendingPool lendingPool;
    address stkAave;
    

    function initialize(
        address forge_, 
        address _lendingPool,
        address token_,
         address uRouterV2_,
         address _stkAave
    ) public {
            _addToken( token_ );
            setForge( forge_ );
            lendingPool    = ILendingPool(_lendingPool);
            uRouterV2      = uRouterV2_;
            stkAave        = _stkAave;

    }

    function _addToken(address _token) public {
        bool added = addToken(_token);
        require(added);

    }

    function getHighestApyToken() public returns( uint, address ) {
        uint apy = 0;
        address addr;
        for (uint i = 0; i < tokens().length; i++){
            (,,,uint currentLiquidityRate,,,,,,,,) = LendingPool.getReserveData( token(i) );
            uint percentDepositAPY = 100 * currentLiquidityRate / RAY;
            if(percentDepositAPY > apy) {
                addr = token(i);
                apy = percentDepositAPY;
            }
        }
        return (addr, apr);
    }
    
    function invest() public override {
        if (tokenInvestedIn != token(0)){
            _swap(token(0), tokenInvestedIn);
            uint balance = IERC20(tokenInvestedIn).balanceOf();
            IERC20(tokenInvestedIn).safeApprove(lendingPool, balance);
            lendingPool.deposit(token(0), balance, address(this), 0);
        } 
        IERC20(token(0)).safeApprove(lendingPool, underlyingBalanceInModel);
        lendingPool.deposit(token(0), underlyingBalanceInModel(), address(this), 0);
        
    }

    function underlyingBalanceInModel() public override view returns ( uint256 ){
        return IERC20( token( 0 ) ).balanceOf( address( this ) );
    }

    // function underlyingBalanceWithInvestment() public override view returns ( uint256 ){
    //     return underlyingBalanceInModel().add()
    // }

    function _claimStkAave(address[] _token ) public {
        for(uint i = 0; i < _token.length; i++){
            (,,,,,,,,address aTokenAddress,,,) = LendingPool.getReserveData( _token );
            address incentivesController = IAToken(aTokenAddress).getIncentivesController();
            IAaveIncentivesController(incentivesController).claimRewards(_token, type(uint).max, address(this));
            // @todo
            // claim rewards and swap to underlying
        }
        

    }

    function reInvest() public {
        (address _token,) = getHighestApyToken();
        if(tokenInvestedIn != _token){
            lendingPool.withdraw(tokenInvestedIn, type(uint).max, address(this));
            _swap(tokenInvestedIn, _token);
            lendingPool.deposit(_token, IERC20(_token).balanceOf(), address(this), 0);
        }
        investIn(_token);
        invest();

    }

    function swapAaveToUnderlying(){
        // @todo
        // swap redeemed stkAave to underlying
    }

    function investIn(address _token) {
        tokenInvestedIn = _token;
    }

    
    function withdrawAllToForge() public OnlyForge override {
        lendingPool.withdraw(tokenInvestedIn, type(uint).max, address(this));
        if(tokenInvestedIn != token(0)){
            _swap( tokenInvestedIn , token(0));
        }
        _claimStkAave(tokenInvestedIn);
        uint balance = IERC20(token(0)).balanceOf(address(this));
        IERC20(token(0)).safeTransfer(to, balance);
    }

    
    function withdrawToForge( uint256 amount ) public OnlyForge override {
        withdrawTo(amount, forge());
    }
    
    function withdrawTo(uint256 amount, address to) public OnlyForge override {
        // @todo
        // figure out how to calculate the balance of underlying of aTokens without withdrawing
        uint balance = IERC20(token(0)).balanceOf(address(this));
        balance = 
        lendingPool.withdraw(tokenInvestedIn, type(uint).max, address(this));
        if(tokenInvestedIn != token(0)){
            _swap( tokenInvestedIn , token(0));
        }
        
        IERC20(token(0)).safeTransfer(to, balance);
    }

    function _swap(address token0, address token1) internal {
        // Hard Work Now! For Punkers by 0xViktor
        uint balance = IERC20(token0).balanceOf(address(this));
        if (balance > 0) {

            IERC20(token0).safeApprove(uRouterV2, balance);
            
            address[] memory path = new address[](3);
            path[0] = address(token0);
            path[1] = IUniswapV2Router02( uRouterV2 ).WETH();
            path[2] = address( token1 );

            IUniswapV2Router02(uRouterV2).swapExactTokensForTokens(
                balance,
                1,
                path,
                address(this),
                block.timestamp + ( 15 * 60 )
            );

            emit Swap(balance, underlyingBalanceInModel());
        }
    }

}