// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/ModelInterface.sol";
import "../ModelStorage.sol";
import "../3rdDeFiInterfaces/ILendingPool.sol";
import "../3rdDeFiInterfaces/IUniswapV2Router.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/IAaveIncentivesController.sol";
import "../interfaces/IStakedToken.sol";

contract AaveModel is ModelInterface, ModelStorage{
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    address tokenInvestedIn; 
    address uRouterV2;
    ILendingPool lendingPool;
    address stkAave;
    address incentivesController;
    address aaveToken;

    uint256 internal constant RAY = 1e27;
    uint constant coolDownPeriod = 7 days; 
    uint coolDownStart;


    
    event Swap(uint amount, address tok0, address tok1);
    function initialize(
        address forge_, 
        address _lendingPool,
        address token_,
        address uRouterV2_,
        address _stkAave,
        address _aaveToken,
        address incentivesController_
    ) public {
            _addToken( token_ );
            setForge( forge_ );
            lendingPool    = ILendingPool(_lendingPool);
            uRouterV2      = uRouterV2_;
            stkAave        = _stkAave;
            incentivesController = incentivesController_;
            aaveToken = _aaveToken;

    }

    function _addToken(address _token) public {
        bool added = addToken(_token);
        require(added);

    }

    function getHighestApyToken() public view returns( address, uint ) {
        uint apy;
        address addr;
        for (uint i = 0; i < tokens().length; i++){
            DataTypes.ReserveData memory data;
            data = lendingPool.getReserveData( token(i) );
            uint percentDepositAPY = 100 * data.currentLiquidityRate / RAY;
            if(percentDepositAPY > apy) {
                addr = token(i);
                apy = percentDepositAPY;
            }
        }
        return (addr, apy);
    }
    
    function invest() public override {
        if (tokenInvestedIn != token(0)){
            _swap(token(0), tokenInvestedIn, underlyingBalanceInModel());
            IERC20(tokenInvestedIn).safeApprove(address(lendingPool), balanceOfTokenInvested());
            lendingPool.deposit(tokenInvestedIn, balanceOfTokenInvested(), address(this), 0);
        } 
        IERC20(token(0)).safeApprove(address(lendingPool), underlyingBalanceInModel());
        lendingPool.deposit(token(0), underlyingBalanceInModel(), address(this), 0);
        
    }

    function underlyingBalanceInModel() public override view returns ( uint256 ){
        return IERC20( token( 0 ) ).balanceOf( address( this ) );
    }
    function balanceOfTokenInvested() public view returns ( uint256 ){
        return IERC20( tokenInvestedIn ).balanceOf( address( this ) );
    }

    function underlyingBalanceWithInvestment() public override view returns ( uint256 ){
        DataTypes.ReserveData memory data;
        data = lendingPool.getReserveData( tokenInvestedIn );
        return IERC20(data.aTokenAddress).balanceOf(address(this));
    }

    function _claimStkAave(address[] calldata _token ) public {
        for(uint i = 0; i < _token.length; i++){
            // (,,,,,,,,address aTokenAddress,,,) = LendingPool.getReserveData( _token );
            // address incentivesController = IAToken(aTokenAddress).getIncentivesController();
            IAaveIncentivesController(incentivesController).claimRewards(_token, type(uint).max, address(this));
        }
        // claim rewards
        IStakedToken(stkAave).cooldown();
        coolDownStart = block.timestamp;
    }

    function reInvest() public {
        (address _token,) = getHighestApyToken();
        if(tokenInvestedIn != _token){
            lendingPool.withdraw(tokenInvestedIn, type(uint).max, address(this));
            _swap(tokenInvestedIn, _token, balanceOfTokenInvested());
            lendingPool.deposit(_token, IERC20(_token).balanceOf(address(this)), address(this), 0);
        }
        investIn(_token);
        invest();

    }

    function swapStkAave() internal {
        require(block.timestamp > (coolDownStart + coolDownPeriod));
        // redeem staked aave token
        IStakedToken(stkAave).redeem(address(this), IERC20(stkAave).balanceOf(address(this)));
        uint bal = IERC20(aaveToken).balanceOf(address(this));
        // swap redeemed stkAave to underlying
        _swap(aaveToken, token(0), bal);
    }

    function investIn(address _token) internal {
        tokenInvestedIn = _token;
    }

    
    function withdrawAllToForge() public OnlyForge override {
        lendingPool.withdraw(tokenInvestedIn, type(uint).max, address(this));
        if(tokenInvestedIn != token(0)){
            _swap( tokenInvestedIn , token(0), balanceOfTokenInvested());
        }
        IERC20(token(0)).safeTransfer(forge(), underlyingBalanceInModel());
    }

    
    function withdrawToForge( uint256 amount ) public OnlyForge override {
        withdrawTo(amount, forge());
    }
    
    function withdrawTo(uint256 amount, address to) public OnlyForge override {
        require(amount > 0, "ZERO_AMOUNT");
        uint oldBalance = IERC20( token(0) ).balanceOf( address( this ) );
        lendingPool.withdraw(tokenInvestedIn, amount, address(this));
        if(tokenInvestedIn != token(0)){
            _swap(tokenInvestedIn, token(0), amount);
        }
        uint newBalance = IERC20( token(0) ).balanceOf( address( this ) );
        require(newBalance.sub( oldBalance ) > 0, "MODEL : REDEEM BALANCE IS ZERO");
        IERC20( token( 0 ) ).safeTransfer( to, newBalance.sub( oldBalance ) );
        
        emit Withdraw( amount, to, block.timestamp);
    }

    function _swap(address token0, address token1, uint amount) internal {
        // Hard Work Now! For Punkers by 0xViktor
        // uint balance = IERC20(token0).balanceOf(address(this));
        require(amount > 0, 'ZERO_AMOUNT');
        IERC20(token0).safeApprove(uRouterV2, amount);
        
        address[] memory path = new address[](3);
        path[0] = address(token0);
        path[1] = IUniswapV2Router02( uRouterV2 ).WETH();
        path[2] = address( token1 );

        IUniswapV2Router02(uRouterV2).swapExactTokensForTokens(
            amount,
            1,
            path,
            address(this),
            block.timestamp + ( 15 * 60 )
        );

        emit Swap(amount, token0, token1);
    }

}