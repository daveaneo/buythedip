pragma solidity ^0.6.12;
//pragma solidity >= 0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "contracts/helpers/console.sol";
import "@chainlink/contracts/src/v0.6/interfaces/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/Base64.sol";
import "contracts/helpers/Base64.sol";
import "interfaces/IUniswapV2Router02.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IUniswapV2Factory.sol";
import "interfaces/IERC20.sol";


// Objectives:
// X //    Mint a token that will purchase dip when BNB goes down to some value
// X //    Look up best way to sort? on blockchain--algorithm efficiency
// X //    Purchase stablecoin
//    Loan stablecoin
//    Redeem stablecoin
// X //    Purchase BNB
// X //    Upgrade NFT to new graphic
//    Stake NFT to earn time-limited rewards


library UniswapHelpers {

    function _swapExactTokensForETH(uint256 tokenAmount, address tokenContractAddress, address to, IUniswapV2Router02 _router, uint256 _swapSlippage) internal  returns (uint256, uint256){

        address[] memory path = new address[](2);
        path[0] = tokenContractAddress; //address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD); // USDT Rinkeby
        path[1] = _router.WETH();

//        uint256 minTokensToReceive; // Local scope for many variables
//        {
//            IUniswapV2Factory _UFactory = IUniswapV2Factory(_router.factory());
//            address _tokenPair = _UFactory.getPair(_router.WETH(), tokenContractAddress);
//            (uint256 Res0, uint256 Res1,) = IUniswapV2Pair(_tokenPair).getReserves();
//            require(Res1!=0, "No tokens in Res1");
//            uint256 ETHPricePerBabyDoge =  (10**18)*Res1/Res0;
//            require(ETHPricePerBabyDoge!=0, "ETHPricePerBabyDoge equals zero."); // why? Not dividing by zero anyore
//            minTokensToReceive = tokenAmount * (10000 - _swapSlippage);
//            minTokensToReceive = minTokensToReceive * ETHPricePerBabyDoge;
//            minTokensToReceive = minTokensToReceive / 10**18  / 10000; // ETH TO RECEIVE
//        }

//         for Pancakeswap
        uint256 minTokensToReceive; // Local scope for many variables
        {
            uint256 receivable = _router.getAmountsOut(tokenAmount, path)[0];
            minTokensToReceive = receivable * (10000 - _swapSlippage)/10000;
        }

        uint256[] memory amounts = _router.swapExactTokensForETH(
            tokenAmount,
            minTokensToReceive, // set _swapSlippage to 10000 to accept anything
            path,
            to,
            block.timestamp
        );

        require(amounts[0] != 0 && 0 != amounts[1], "swapExactETH failed.");
        return (amounts[0], amounts[1]);
    }

    function _addLiquidity(uint256 tokenAmount, address contractAddress, IUniswapV2Router02 _router, uint256 coinAmount) internal returns(uint256) {
        (uint amountToken,,) =  _router.addLiquidityETH{value: coinAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            contractAddress,
            block.timestamp
        );

        return amountToken;
    }

    function _swapEthForTokens(uint256 ethAmount, address tokenContractAddress, address to, IUniswapV2Router02 _router, uint256 _swapSlippage) internal returns (uint256, uint256) {
        address[] memory path = new address[](2);
        path[0] = _router.WETH();
        path[1] = tokenContractAddress; //address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD); // USDT Rinkeby

        // For Ethereum
//        uint256 minTokensToReceive;
//        {
//            IUniswapV2Factory _UFactory = IUniswapV2Factory(_router.factory());
//            address _tokenPair = _UFactory.getPair(_router.WETH(), tokenContractAddress);
//            (uint256 Res0, uint256 Res1,) = IUniswapV2Pair(_tokenPair).getReserves(); // baby doge is Res0
//            require(Res0 !=0, "No tokens in Res0");
//            uint256 tokensPerETH =  ((10**18)*Res0)/Res1; // For 10**18
//            require(tokensPerETH!=0, "tokensPerETH equals zero.");
//            minTokensToReceive = ethAmount * (10000 - _swapSlippage) * tokensPerETH;
//            minTokensToReceive = minTokensToReceive / (10**18) / 10000;
//            minTokensToReceive = minTokensToReceive / (10**18) / 10000;
//        }

        // for Pancakeswap
        uint256 minTokensToReceive; // Local scope for many variables
        {
//            IUniswapV2Factory _UFactory = IUniswapV2Factory(_router.factory());
//            address _tokenPair = _UFactory.getPair(_router.WETH(), tokenContractAddress);
            uint256 receivable = _router.getAmountsOut(ethAmount, path)[0];
            minTokensToReceive = receivable * (10000 - _swapSlippage)/10000;
        }

        // todo: For whatever reason, this is not working correctly when using pancakeswap
        uint256[] memory amounts = _router.swapExactETHForTokens{value: ethAmount}( // ethAmount, path, to, block.timestamp ){ //ExactTokensForETHSupportingFeeOnTransferTokens(
            minTokensToReceive,
            path,
            to,
            block.timestamp + 360 // 30 minutes before reverting
        );

        require(amounts[0] != 0 && 0 != amounts[1], "swapExactETH failed.");
        return (amounts[0], amounts[1]);
    }
}

// Address: 0x26EA744E5B887E5205727f55dFBE8685e3b21951 // Same for BSC, Polygon, ETH
interface IyUSDC {
    function withdraw(uint256 _shares) external;
    function deposit(uint256 _amount) external;

    function balance() external view returns (uint256);
    function balanceDydx() external view returns (uint256);
    function balanceCompound() external view returns (uint256);
    function balanceCompoundInToken() external view returns (uint256);
    function balanceFulcrumInToken() external view returns (uint256);
    function balanceFulcrum() external view returns (uint256);
    function balanceAave() external view returns (uint256);
    function recommend() external view returns (uint256);
    function rebalance() external;
    function calcPoolValueInToken() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function balanceOf(address _address) external view returns(uint);

}

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

contract DipStaking is Ownable, ERC721TokenReceiver  {
    BuyTheDipNFT public BTD;
    mapping(uint256=>address) public previousOwner;
    mapping(uint256=>uint256) public stakeStartTimestamp; // we went to disencentivize people who game the system? Maybe don' need to worry
    mapping(uint256=>uint256) public moneys; // we went to disencentivize people who game the system? Maybe don' need to worry
    uint256 public moneysReceived;
    uint256[] public activeNFTArray;
    uint256 public reservedFundsForStakers=0;
    uint256 public reservedFundsForOwners=0;

    uint256 MINSTAKINGTIME = 60*60*24*7; // 1 week

    constructor(address _BuyTheDipNFTAddress) public {
        // set _BuyTheDipNFTAddress
        BTD = BuyTheDipNFT(payable(_BuyTheDipNFTAddress));
    }

    /** @dev Unpacks 3 uints into 1 uint to (256) -> (128, 64, 64)
        @param _userDeposit -- 256 bit encoding of deposit, blockDepositAmount, and blockDeposited
      */
    function unpackData(uint256 _userDeposit) internal pure returns (uint256, uint256, uint256){
        uint256 _deposit = uint256(uint128(_userDeposit));
        uint256 _blockDepositAmount = uint256(uint64(_userDeposit >> 128));
        uint256 _blockDeposited = uint256(uint64(_userDeposit >> 192));
        return (_deposit, _blockDepositAmount, _blockDeposited);
    }

    /** @dev Packs 3 uints into 1 uint to save space (128, 64, 64) -> 256
        @param _deposit -- total deposit, uint128
        @param _blockDepositAmount -- amount deposited in this block, uint64
        @param _blockDeposited -- block.timestamp, uint64
      */
    function packData(uint256 _deposit, uint256 _blockDepositAmount, uint256 _blockDeposited) internal pure returns (uint256){
        uint256 ret = _deposit;
        ret |= _blockDepositAmount << 128;
        ret |= _blockDeposited << 192;
        return ret;
    }


    receive() external payable{
      // when receiving ETH, split it equally among all stakers and founders/owners
      // create clever way to not spend a lot of gas

    }

    /** @dev Adds up all active energy contributed by stakers
      */
    function getTotalStakingEnergy() public view returns(uint256) {
        // Make sure everyone is flushed.
        uint256 _total = 0;
        for(uint256 i = 0; i < activeNFTArray.length; i++){ // is activeNFTArray.length dynamic here?
            uint256 _id = activeNFTArray[i];
            if(BTD.tokenIdToEnergy(_id) + stakeStartTimestamp[_id] > block.timestamp){
                _total += block.timestamp - stakeStartTimestamp[_id];
            }
            else {
                _total += BTD.tokenIdToEnergy(_id);
            }
        }
        return _total == 0 ? 1: _total;
    }

    /** @dev Remove NFT from staking pool
        @param _id -- id of NFT. Must be previous owner to call
      */
    function unstake(uint256 _id) external {
        require(msg.sender == previousOwner[_id], "Not owner.");
        require(stakeStartTimestamp[_id] + MINSTAKINGTIME > block.timestamp, "Minimum staking period not met.");

        withdrawRewards(_id);
        BTD.approve(previousOwner[_id], _id); // todo -- necessary?
        BTD.safeTransferFrom(address(this), previousOwner[_id], _id, "");

        // Remove from array
        for (uint256 i=0; i< activeNFTArray.length; i++) {
            if(activeNFTArray[i]==_id){
                activeNFTArray[i] = activeNFTArray[activeNFTArray.length - 1];
                activeNFTArray.pop();
                break;
            }
        }

        // delete information to save space
        delete previousOwner[_id];
        delete stakeStartTimestamp[_id];
        delete moneys[_id];
    }

    /** @dev Withdraw native coin, which has been earned as a reward.
        @param _id -- id of NFT. Must be previous owner to call
      */
    function withdrawRewards(uint256 _id) public {
        require(msg.sender == previousOwner[_id], "Not owner.");
        flushTokenRewardsOf(_id);
        reservedFundsForStakers -= moneys[_id];
        uint256 _reward = moneys[_id];
        moneys[_id] = 0;
        (bool success, ) = address(previousOwner[_id]).call{value : _reward}("Releasing rewards to NFT owner.");
        require(success, "Transfer failed.");
    }

    /** @dev Withdraw native coined, earned as reward, and set asid for owners/wallet
      */
    function withdrawRewardsForOwners() external {
        require(msg.sender == owner(), "Not owner.");
        uint256 _reward = reservedFundsForOwners;
        reservedFundsForOwners = 0;
        (bool success, ) = owner().call{value : _reward}("Releasing rewards to owner.");
        require(success, "Transfer failed.");
    }

    /** @dev Returns amount of staking funds available, total minus reserved for specific stakers who have been removed from active staking and from owners
      */
    function getAvailableStakingFunds() public view returns(uint256){
        return (address(this).balance - reservedFundsForStakers - reservedFundsForOwners);
    }

    // todo--combine with flushInactive
    /** @dev moves token rewards from the pool and puts it in a separate account for one token. Decreases energy.
        @param _id -- token id
      */
    function flushTokenRewardsOf(uint256 _id) internal {
        uint256 _rewards = getAvailableStakingFunds() * getActiveEnergyOfToken(_id) / getTotalStakingEnergy();
        moneys[_id] += _rewards;
        reservedFundsForStakers += _rewards;

        // if out of energy
        if(BTD.tokenIdToEnergy(activeNFTArray[_id]) + stakeStartTimestamp[_id] < block.timestamp){
            BTD.setEnergy(_id, 0);
            activeNFTArray[_id] = activeNFTArray[activeNFTArray.length - 1];
            activeNFTArray.pop();
        }
        else {
            stakeStartTimestamp[_id] = block.timestamp;
            BTD.setEnergy(_id, BTD.tokenIdToEnergy(_id) - getActiveEnergyOfToken(_id));
        }
//        BTD.setEnergy(_id, BTD.tokenIdToEnergy(_id) - getActiveEnergyOfToken(_id));
//        stakeStartTimestamp[_id] = block.timestamp;
        // todo--confirm functionality. Should this  also move _id to inactive stakers? What calls this?


    }

    /** @dev Get energy used since timestamp for specific NFT
        @param _id -- id of NFT. Must be previous owner to call
      */
    function getActiveEnergyOfToken(uint256 _id) public view returns(uint256){
            uint256 _energy;
            if(BTD.tokenIdToEnergy(_id) + stakeStartTimestamp[_id] > block.timestamp){
                _energy = block.timestamp - stakeStartTimestamp[_id];
            }
            else {
                _energy = BTD.tokenIdToEnergy(_id);
            }
            return _energy;
    }

    /** @dev Flush all staked NFTs that have used up their energy
      */
    function flushInactive() internal {
        uint256 _id;
        uint256 _rewards;
        uint256 _totalEnergy = getTotalStakingEnergy(); // todo-- do we need to recalculate this in the for loop?
        for(uint256 i = 0; i < activeNFTArray.length; i++){ // is activeNFTArray.length dynamic here?
            if(BTD.tokenIdToEnergy(activeNFTArray[i]) + stakeStartTimestamp[i] < block.timestamp){
//                _id = activeNFTArray[i];
//                _rewards = getAvailableStakingFunds() * getActiveEnergyOfToken(_id) / _totalEnergy;
//                moneys[_id] += _rewards;
//                BTD.setEnergy(_id, 0);
//                reservedFundsForStakers += _rewards;
//                activeNFTArray[i] = activeNFTArray[activeNFTArray.length - 1];
//                activeNFTArray.pop();
                flushTokenRewardsOf(activeNFTArray[i]);
            }
        }
    }

    /** @dev Get all NFTs owned by owner.
        @param _addy -- address to get list of NFTs of
        @return -- list of token IDs owned by addy
      */
    function getAllNFTsByPreviousOwner(address _addy) public view returns (uint256[] memory){
        uint256 total=0;
        uint256 _tokenCounter = BTD.tokenCounter();
        for(uint256 i=0;i<_tokenCounter;i++){
            if(previousOwner(i)==_addy){
                total +=1;
            }
        }

        uint256[] memory owned = new uint256[](total);
        uint256 count=0;

        // Two cycles are needed because of inability to push integers to memory array
        for(uint256 i=0;i<_tokenCounter;i++){
            if(count>=total){ break; }
            if(previousOwner(i)==_addy){
                owned[count]=i;
                count +=1;
            }
        }
        return owned;
    }



    /** @dev Upkeep when receiving NFTs
      */
//    function stake(uint256 _id) external returns(bool) {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external override returns(bytes4){
        // receive tokens
        // require to have power and correct dip status
        // record previous owner
        // set time record for when can remove token
        // Create system for recording, distributing ETH
        // Variables
            // One timestamp for each NFT, mapping(uint256=>uint256), could be less if we wanted to include cash holding
            // contract.balance - holdings (various) is used to cash out
            // Each receive() updates which active NFTs and cashes out those that are inactive
          require(BTD.tokenIdToIsWaitingToBuy(_tokenId)==false,"Can't stake while waiting to buy dip.");
          require(BTD.tokenIdToEnergy(_tokenId) > 0, "Not enough energy.");
          stakeStartTimestamp[_tokenId] = block.timestamp;
          previousOwner[_tokenId] = _from; //tx.origin; //msg.sender;
          activeNFTArray.push(_tokenId);

        //        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return this.onERC721Received.selector;
    }
}

// VRFConsumerBase,
contract BuyTheDipNFT is ERC721, KeeperCompatibleInterface, Ownable  {
    uint256 public tokenCounter;

    // Better to use a struct?
    mapping(uint256 => uint8) public tokenIdToDipLevel; // Number of times NFT has bought the dip
    mapping(uint256 => uint256) public tokenIdToDipValue; // Strike Price
    mapping(uint256 => uint256) public tokenIdToDipPercent; // Percent Drop
    mapping(uint256 => uint256) public tokenIdToStableCoin; // Amount of USDT purchased
    mapping(uint256 => bool) public tokenIdToIsWaitingToBuy; // True/False if waiting to buy
    mapping(uint256 => uint256) public tokenIdToEnergy; // True/False if waiting to buy

//    uint256 internal fee;
    uint256 public highestDip = ~uint256(0); //2**127 - 1; //todo: ~0
    uint256 swapSlippage = 10000; // full slippage
    uint256 public totalStableCoin = 0;

    uint256 private immutable interval = 60;
    uint256 private lastTimeStamp;
    uint256 private MINCOINDEPOSIT = 10**14;
    uint256 private EARLYWITHDRAWALFEEPERCENT = 300; // (out of 100*100)
    uint256 private NORMALWITHDRAWALFEEPERCENT = 100; // (out of 100*100)
    uint256 private MINTFEE = 10**12; // todo: add this to account and make sure can withdraw
    uint256 private STABLECOINDUSTTHRESHOLD = 10**6/10; //10 cents
    uint256 private PROFITRELEASETHRESHOLD = 10**16;
    address public profitReceiver;
    uint256 private contractStablecoinProfit;

    ///////////////////////////////////////////
    ///////     CONFIG INFORMATION     ////////
    ///////////////////////////////////////////

    // Stable Coin Lending Vault
//    IyUSDC yUSDC = IyUSDC(0x26EA744E5B887E5205727f55dFBE8685e3b21951); // ETH/BSC/Polygon
    IyUSDC yUSDC = IyUSDC(0x232dA19534032CBfE838e5f620C495D52061e947); // Rinkeby
//    IyUSDC yUSDC = IyUSDC(0x597ad1e0c13bfe8025993d9e79c69e1c0233522e); // Ropstein
//    IyUSDC yUSDC = IyUSDC(0xd6aD7a6750A7593E092a9B218d66C0A814a3436e); // BSC Testnet

    //ETHEREUM MAIN
//    IUniswapV2Router02 router = IUniswapV2Router02(); // Ethereum Mainnet
//    address factory = address(); // Ethereum Mainnet
//    address StableCoinAddress = address(); // USDT, Ethereum Mainnet
//    address StableCoinAddress = address(); // USDC, Ethereum Mainnet


//  Rinkeby
    IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // testnet
    address factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // testnet
//    address StableCoinAddress = address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD); // USDT, Rinkeby
    address StableCoinAddress = address(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b); // USDC, Rinkeby

    // BSC TESTNET
    // PanckeSwap site: https://pancake.kiemtienonline360.com/#/swap
//    IUniswapV2Router02 router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // testnet
//    address factory = address(0x6725F303b657a9451d8BA641348b6761A6CC7a17); // testnet
//    address StableCoinAddress = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7); // BUSD, BSC testnet --- WORKS
//    address StableCoinAddress = address(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684); // USDT, BSC testnet --- WORKS

    //BSC Main net
//    IUniswapV2Router02 router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // BSC Main
//    address factory = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); // BSC Main
//    address StableCoinAddress = address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD); // BUSD? CONFIRM?

    IERC20 usdc = IERC20(StableCoinAddress);

//    AggregatorV3Interface internal priceFeed;
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) // ETH/USD, Ethereum mainnet
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); // ETH/USD, Rinkeby (Ethereum testnet)
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); // ETH/USD, Kovan (Ethereum testnet
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // BNB/USD, bsc testnet
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB/USD, bsc mainnet


    address public addy;

    event CoinsReleasedToOwner(
        uint256 amount,
        uint256 date
    );


event Received(address sender, uint amount);

    modifier onlyKeeper {
       require(true);
       //require(msg.sender == owner); // ToDo: modify
      _;
   }

//    constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyhash)
    constructor()
    public
//    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("WeBuyTheDip", "DIP")
    {
        tokenCounter = 0;
//        keyHash = _keyhash;
//        fee = 0.1 * 10 ** 18;

        //todo: remove, clean up
//        priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) // ETH/USD, Ethereum mainnet
//        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); // ETH/USD, Rinkeby (Ethereum testnet)
//        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); // ETH/USD, Kovan (Ethereum testnet
//        priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // BNB/USD, bsc testnet
//        priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB/USD, bsc mainnet
        profitReceiver = owner();
        lastTimeStamp = block.timestamp;
    }

    // todo: Create liquidity pool for USDC on pancakeswap BSC testnet
    function createCollectible(uint32 percentDrop)
        public payable returns (bytes32){
            require (msg.value + MINTFEE >= MINCOINDEPOSIT, "Not enough native coin.");
            require(percentDrop < 100, "Percent X must conform to: 10 <= X < 100"); // todo: adjust 10% after testing

            updateAllBalances();

            contractStablecoinProfit += MINTFEE; // STABLECOIN or not?
            uint256 newItemId = tokenCounter;
            tokenCounter = tokenCounter + 1;
            _safeMint(msg.sender, newItemId);

            tokenIdToDipLevel[newItemId] = 0;
            tokenIdToDipValue[newItemId] = (100 - percentDrop) * getLatestPrice() / 100;
            tokenIdToDipPercent[newItemId] = percentDrop;

//            tokenIdToStableCoin[newItemId] = swapETHForTokens(newItemId, msg.value);
            (, uint256 stablecoinReceived) = UniswapHelpers._swapEthForTokens(msg.value, StableCoinAddress, address(this), router, swapSlippage);
            tokenIdToStableCoin[newItemId] = msg.value * stablecoinReceived/ (msg.value + MINTFEE);
            contractStablecoinProfit += MINTFEE * stablecoinReceived/ (msg.value + MINTFEE);

            require(tokenIdToStableCoin[newItemId] > 0, "Error! No tokens bought.");

            // Lend Stablecoin // todo--was having issues
            lendStableCoin(tokenIdToStableCoin[newItemId]);

            // Update highestDip if needed
            if(tokenIdToDipValue[newItemId] > highestDip){
                highestDip = tokenIdToDipValue[newItemId];
            }

            totalStableCoin += stablecoinReceived; //tokenIdToStableCoin[newItemId];
            tokenIdToIsWaitingToBuy[newItemId] = true;


            _setTokenURI(newItemId, tokenURI(newItemId));

            if(newItemId==2) { // temp todo: remove
//                IERC20(StableCoinAddress).approve(address(router), tokenIdToStableCoin[newItemId]);
////                UniswapHelpers._swapExactTokensForETH(tokenIdToStableCoin[newItemId], StableCoinAddress, address(this), router, swapSlippage);
//                (ETHSENT, USDTRECEIVED) = UniswapHelpers._swapExactTokensForETH(tokenIdToStableCoin[newItemId], StableCoinAddress, ownerOf(newItemId),  router, swapSlippage);
                performUpkeepTest();
            }

//             emit requestedCollectible(newItemId);
    }

    // todo: combine shared features from createCollectible
    /** @dev Buying the dip again on existing NFTs
      */
    function redip(uint256 _tokenId) public payable returns (bytes32) {
        // Constrain deposit to range based on previous deposits? Or always absolute minimum?
        require (msg.value >= MINCOINDEPOSIT, "Not Enough BNB--or whatever");
        require(tokenIdToIsWaitingToBuy[_tokenId] == false, "already in process of buying dip.");

        updateAllBalances();

        tokenIdToDipValue[_tokenId] = (100 - tokenIdToDipPercent[_tokenId]) * getLatestPrice() / 100;
        _setTokenURI(_tokenId, tokenURI(_tokenId));

        (, tokenIdToStableCoin[_tokenId]) = UniswapHelpers._swapEthForTokens(msg.value, StableCoinAddress, address(this), router, swapSlippage);
        require(tokenIdToStableCoin[_tokenId] > 0, "Error! No tokens bought.");

        lendStableCoin(tokenIdToStableCoin[_tokenId]);

        totalStableCoin += tokenIdToStableCoin[_tokenId];
        tokenIdToIsWaitingToBuy[_tokenId] = true;

        if(tokenIdToDipValue[_tokenId] > highestDip){
            highestDip = tokenIdToDipValue[_tokenId];
        }

        // Emit LimitOrderCreated
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    // Required to receive ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    /** @dev Update balances with new interest values
      */
    function updateAllBalances() internal {
        uint256 _addedTokens;
        uint256 _newTotal = totalStableCoin;
        uint256 _newIndividialBalance;
        for(uint256 i = 0; i < tokenCounter;i++){
            if(tokenIdToIsWaitingToBuy[i]==true){
                _newIndividialBalance = getStableCoinBalanceGivenId(i);
                // todo -- will thise ever be negative? If so, ramifications?
                // todo -- Have threshold to ignore dust.
                _addedTokens = _newIndividialBalance > tokenIdToStableCoin[i] ? _newIndividialBalance - tokenIdToStableCoin[i] : 0;
                if(_addedTokens > STABLECOINDUSTTHRESHOLD ){
                    tokenIdToStableCoin[i] = _newIndividialBalance;
                    _newTotal += _addedTokens;
                }
            }
        }
        totalStableCoin = _newTotal;
    }


    // todo -- no need to recalculate balances after destroying
    // protect existing accounts from sharing their rewards. This will be expensive!
    function destroyAndRefund(uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId), "Must be token owner.");
        if (tokenIdToDipValue[_tokenId] <= getLatestPrice()){
            buyTheDip(_tokenId);
        }
        // buy with penalty
        else {
            // get stablecoin amount after penalty
            uint256 _withdrawal = retrieveLentStablecoins(_tokenId, EARLYWITHDRAWALFEEPERCENT);

            IERC20(StableCoinAddress).approve(address(router), _withdrawal);
            (uint256 ETHSent, uint256 USDTReceived) = UniswapHelpers._swapExactTokensForETH(_withdrawal, StableCoinAddress, ownerOf(_tokenId), router, swapSlippage);
        }
    }

    /** @dev Get all NFTs owned by owner.
        @param _addy -- address to get list of NFTs of
        @return -- list of token IDs owned by addy
      */
    function getAllNFTsByOwner(address _addy) public view returns (uint256[] memory){
        uint256 total=0;

        for(uint256 i=0;i<tokenCounter;i++){
            if(ownerOf(i)==_addy){
                total +=1;
            }
        }

        uint256[] memory owned = new uint256[](total);
        uint256 count=0;

        // Two cycles are needed because of inability to push integers to memory array
        for(uint256 i=0;i<tokenCounter;i++){
            if(count>=total){ break; }
            if(ownerOf(i)==_addy){
                owned[count]=i;
                count +=1;
            }
        }

        return owned;
    }


    function buyTheDip(uint256 _tokenId) public onlyKeeper {
        // Confirm price
        require(tokenIdToDipValue[_tokenId] <= getLatestPrice(), 'Price above dipLevel');
        uint256 initialBalance = address(this).balance;
        uint256 _withdrawal = retrieveLentStablecoins(_tokenId, NORMALWITHDRAWALFEEPERCENT);

        //todo: (ETHSent, USDTReceived) may be reversed
        IERC20(StableCoinAddress).approve(address(router), _withdrawal);
        (uint256 ETHSent, uint256 USDTReceived) = UniswapHelpers._swapExactTokensForETH(_withdrawal, StableCoinAddress, ownerOf(_tokenId), router, swapSlippage);

        emit CoinsReleasedToOwner(USDTReceived, block.timestamp);
        tokenIdToIsWaitingToBuy[_tokenId] = false;
        if (tokenIdToDipLevel[_tokenId] < 7) { tokenIdToDipLevel[_tokenId] += 1; }

        tokenIdToEnergy[_tokenId] += tokenIdToStableCoin[_tokenId] * tokenIdToDipPercent[_tokenId] **2 / 10000 * tokenIdToDipLevel[_tokenId]; // todo -- choose energy formula

        //temp todo -- remove after testing
        tokenIdToEnergy[_tokenId] = 10000;
    }


    function getLatestPrice() public view returns (uint256) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return uint256(price);
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval && highestDip <= getLatestPrice();
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // todo: change to external after testing
    function performUpkeep(bytes calldata /* performData */) external override {
        // todo
    }

    function performUpkeepTest() public {
        lastTimeStamp = block.timestamp;
//        uint256 _highestDip = ~uint256(0); // todo: should this be the global highestDip
        uint256 latestPrice = getLatestPrice();

        for(uint256 i=0;i<tokenCounter;i++){
            if (tokenIdToIsWaitingToBuy[i] == true) {
                if (tokenIdToDipValue[i] <= latestPrice ){
                    buyTheDip(i);
                }
            }
            else{
                if ( tokenIdToDipValue[i] < highestDip) {
                    highestDip = tokenIdToDipValue[i];
                }
            }
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        bool isWaitingToBuy = tokenIdToIsWaitingToBuy[_tokenId];
        uint256 _dipLevel = tokenIdToDipLevel[_tokenId];
        uint256 _strikePrice = uint256(tokenIdToDipValue[_tokenId]);
        uint256 _RADIUS = 78; // 80 - 2
        uint256 _latestPrice = uint256(getLatestPrice());
        uint256 _circleRadius;
        if (!isWaitingToBuy) {
            _circleRadius = _RADIUS;
        }
        else {
            _circleRadius = (_latestPrice > ((_strikePrice)*100/(100 - tokenIdToDipPercent[_tokenId]))) ? 0 : uint256(_RADIUS*(100 - 100*(_latestPrice - _strikePrice)/_latestPrice)/100); // temp, check for negative
        }
        uint256 _energy = tokenIdToEnergy[_tokenId];

        string memory mainImage;

        // Waiting to buy dip
        // todo: update this, as both are doing the circle
        if (isWaitingToBuy==true){
            mainImage = string(abi.encodePacked(
//                "%3Ccircle cx='175' cy='225' r='100' stroke='black' stroke-width='3' stroke-dasharray='15' fill='white' /%3E",
//                "%3Ccircle cx='175' cy='225' r='", uint2str(uint256(_circleRadius)) ,"' stroke='' stroke-width='0' fill='red' /%3E"
//                "%3Ccircle style='fill:#ffffff;stroke:#0045bb;stroke-width:1.38;stroke-linejoin:round;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none' id='path846' cx='85' cy='85' r='100' /%3E",
//                "%3Ccircle style='fill:#ffffff;stroke:#000000;stroke-width:4;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0.32' id='path846-5' cx='85' cy='85' r='", uint2str(uint256(_circleRadius))  ,"' /%3E"

                "%3Ccircle style='fill:%23ffffff;stroke:%230045bb;stroke-width:1.38;stroke-linejoin:round;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none' id='path846' cx='175' cy='200' r='100' /%3E ",
                "%3Ccircle style='fill:%23ffffff;stroke:%23000000;stroke-width:4;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0.32' id='path846-5' cx='175' cy='200' r='80' /%3E",
                "%3Ccircle cx='175' cy='200' r='", uint2str(_circleRadius) ,"' stroke='' stroke-width='0' fill='green' /%3E"

            ));
        }
        // Dip Bought
        else {
            mainImage = string(abi.encodePacked(
              // Star -- Temporary
                // DIP
                "%3Ccircle style='fill:%23ffffff;stroke:%230045bb;stroke-width:1.38;stroke-linejoin:round;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none' cx='175' cy='200' r='100' /%3E ",
                "%3Ccircle style='fill:%23ffffff;stroke:%23000000;stroke-width:4;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0.32' cx='175' cy='200' r='80' /%3E",
                "%3Ccircle cx='175' cy='200' r='", uint2str(_circleRadius) ,"' stroke='' stroke-width='0' fill='green' /%3E",


                // Star
//              "%3Cpolygon points='200,110 140,298 290,178 110,178 260,298' ",
//              "style='fill:gold;stroke:purple;stroke-width:5;fill-rule:nonzero;' /%3E ",
              // Checkmark
              "%3Cpath style='fill:none;stroke:%23ffffff;stroke-width:15;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-opacity:1' d='m 139,218 20.4,23.7 56.9,-56.6' /%3E ",
              // Congratulations (text)
              "%3Ctext x='55' y='318' fill='brown'%3ECongratulations! You bought the dip. %3C/text%3E"
            ));
        }

        string memory SVG = string(abi.encodePacked(
            // Container
           "%3Csvg xmlns='http://www.w3.org/2000/svg' width='350' height='350'%3E %3Crect width='350' height='350' style='fill:rgb(255,255,255);stroke-width:3;stroke:rgb(0,0,0)' /%3E",
            // Green BG
           "%3Crect style='opacity:0.33;fill:%23157700;fill-opacity:0.33;stroke:%230b9100;stroke-width:1;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1;paint-order:normal' width='350' height='350' x='0' y='0' /%3E",
           // Green Frame
           "%3Crect style = 'opacity:0.6;mix-blend-mode:normal;fill:none;stroke:%230b9100;stroke-width:15;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1;paint-order:normal' id = 'rect926' width = '315' height = '315' x = '17' y = '17' /%3E %3Crect style = 'opacity:0.33;mix-blend-mode:normal;fill:none;stroke:%230b9100;stroke-width:1.82496;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1;paint-order:normal' id = 'rect926-4' width = '288' height = '288' x = '31' y = '31' /%3E",
           // Data
                // Current Eth Price
           "%3Ctext x='35' y='45' font-weight='bold' fill='brown'%3ECurrent Price:%3C/text%3E",
           "%3Ctext x='175' y='45' font-weight='normal' fill='brown'%3E$", uint2str(uint256(getLatestPrice()), 8, 2), "%3C/text%3E",
                // Strike Price
           "%3Ctext x='35' y='60'  font-weight='bold' fill='brown'%3EStrike Price:%3C/text%3E",
           "%3Ctext x='175' y='60' font-weight='normal' fill='brown'%3E$", uint2str(uint256(_strikePrice), 8, 2), "%3C/text%3E",
                // Stable Coin Invested (conversion)
           "%3Ctext x='35' y='75'  font-weight='bold' fill='brown'%3EUSDC Invested:%3C/text%3E"
            ));

            // Stake-deepness error, so breaking this up
            SVG = string(abi.encodePacked(SVG,
//           "%3Ctext x='175' y='75' font-weight='normal' fill='brown'%3E$", uint2str(uint256(tokenIdToStableCoin[_tokenId]), 6, 2), " %3C/text%3E",
           "%3Ctext x='175' y='75' font-weight='normal' fill='brown'%3E$", uint2str(lendingBalance(_tokenId), 6, 2), " %3C/text%3E",

                // Energy
           "%3Ctext x='35' y='90' font-weight='bold' fill='brown'%3EEnergy:%3C/text%3E",
           "%3Ctext x='175' y='90' font-weight='normal' fill='brown'%3E", uint2str(_energy), "%3C/text%3E",

//                //  TEMPORARY
//           "%3Ctext x='35' y='115' font-weight='bold' fill='brown'%3EACTIVE LENDING:%3C/text%3E",
//           "%3Ctext x='175' y='115' font-weight='normal' fill='brown'%3E", uint2str(lendingBalance(_tokenId)), "%3C/text%3E",
//

           ///// Top Middle
                // Token Id -- Consider putting in top Right
//           "%3Ctext x='35' y='135'  font-weight='bold' fill='brown'%3EToken ID:%3C/text%3E",
//           "%3Ctext x='175' y='135' font-weight='normal' fill='brown'%3E", uint2str(uint256(_tokenId)), "%3C/text%3E",
           "%3Ctext x='50%' y='23' text-anchor='middle' font-weight='bold' font-size='1.1em' fill='white'%3E", uint2str(uint256(_tokenId)), "%3C/text%3E",

          ///// Bottom Middle
           "%3Ctext x='50%' y='338' text-anchor='middle' font-weight='bold' font-size='1.1em' fill='white'%3E ETHEREUM %3C/text%3E",


           // dominant-baseline='middle'


            // Main image
            mainImage,
            // Error Message
            "Unsupported.",
            "%3C/svg%3E"
            ));

//            SVG = '<svg xmlns="http://www.w3.org/2000/svg" height="500" width="500"> <circle cx="250" cy="250" r="200" stroke="black" stroke-width="3" fill="blue" />  </svg>';


        if (_dipLevel >= 0 && _dipLevel < 2){
            return formatTokenURI(_tokenId, svgToImageURI(SVG));
        }
        else {
            return "";
        }
    }


    function svgToImageURI(string memory svg) public pure returns (string memory) {
        bool ENCODE = false;
        string memory baseURL = "data:image/svg+xml;base64,";

        if (!ENCODE) {
            baseURL = "data:image/svg+xml,";
            return string(abi.encodePacked(baseURL,svg));
        }

        //        string memory svgBase64Encoded = Base64.encode((string(abi.encodePacked(svg)))); // bytes?
        string memory svgBase64Encoded = Base64.encode(svg); // bytes?
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function setEnergy(uint256 _tokenId, uint256 _energy) external { // todo: Limit callers to Dip_Staking address
        require(_energy <= tokenIdToEnergy[_tokenId], "Can't increase energy"); // set equal??? check in other places
        tokenIdToEnergy[_tokenId] = _energy;
    }


    function setDipLevel(uint256 _tokenId, uint8 _dipLevel) public onlyOwner {
        require(_dipLevel >=0 && _dipLevel < 8, "Invalid Dip Level");
        require(_tokenId < tokenCounter, "Invalid tokenId");
//        bytes32 _requestId = tokenIdToRequestId[_tokenId];
        tokenIdToDipLevel[_tokenId] = _dipLevel;
    }


    function formatTokenURI(uint256 _tokenId, string memory imageURI) public view returns (string memory) {
        bool ENCODE = true;

        if (ENCODE){
            return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        string(
                            abi.encodePacked(

                                '{"description": "The NFT limit order that earns money!"',
                                ', "external_url": "https://webuythedip.com"',
                                ', "image": "',
                                 imageURI, '"',
                                ', "name": "BuyTheDip"',
                                // attributes
                                ', "attributes": [{"display_type": "number", "trait_type": "Dip Level", "value": ',
                                tokenIdToDipLevel[_tokenId]==0 ? "0": "1",  ' }',
                                ', {"display_type": "number", "trait_type": "Dip Value", "value": ',
                                uint2str(uint(tokenIdToDipValue[_tokenId])),   ' }',
                                ']', // End Attributes
                                '}'
                            )
                        )
                    )
                )
            );
        }
        // This creates bad JSON file, but showed up on Opensea--ONCE!
        else {
            // todo: clean this up
//            return string(
//                abi.encodePacked(
//                    'data:application/json,',
//                    "{'description': 'The NFT limit order that earns money!'",
//                    ", 'external_url': 'https://webuythedip.com'",
//                    ", 'image': '",
//                     imageURI, "'",
//                    ", 'name': 'BuyTheDip'",
//                    // attributes
//                    ", 'attributes': [{'display_type': 'number', 'trait_type': 'Dip Level', 'value': ",
//                    tokenIdToDipLevel[_tokenId]==0 ? '0': '1',  " }",
//                    ", {'display_type': 'number', 'trait_type': 'Dip Value', 'value': ",
//                    uint2str(uint(tokenIdToDipValue[_tokenId])),   " }",
//                    "]", // End Attributes
//                    "}"
//                )
//            );
        }
    }

    function uint2str(uint256 _i, uint256 _totalDecimals, uint256 _decimalPlaces) internal pure returns (string memory _uintAsString) {
        string memory first = uint2str(_i / 10**_totalDecimals);
        string memory second = uint2str((_i % 10**_totalDecimals)/ 10**(_totalDecimals - _decimalPlaces));
        return string(abi.encodePacked(first, ".", second));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    /////////////////////////////
    /////////// yUDSC ///////////
    /////////////////////////////

  // todo -- Test this out
  // todo -- Incorporate into buying dip and buying NFT (2 times)
//  function save(uint amount) internal {
//    usdc.transferFrom(msg.sender, address(this), amount);
//    _save(amount);
//  }


//// two functions. One to retrieve with fee. one to retrieve while buying dip
//  function retrieveLentStablecoins(uint256 _tokenId) internal returns(uint256) {
//    uint256 amount = tokenIdToStableCoin[_tokenId];
//    uint256 balanceShares = yUSDC.balanceOf(address(this));
//    uint256 shareOfShares = amount * balanceShares / totalStableCoin;
//    totalStableCoin = totalStableCoin - amount; // amount invested, not active balance
//    yUSDC.withdraw(shareOfShares);
//    usdc.transfer(address(this), shareOfShares);
////    tokenIdToStableCoin[_tokenId] = 0;
////    uint256 balanceUSDC = usdc.balanceOf(address(this));
////    if(balanceUSDC > 0) {
////      _save(balanceUSDC);
////    }
//    return shareOfShares;
//  }

  // todo -- create mechanism for retrieving profits. Do we keep profits in the vault?
    // Profits are going to be sent to the staking contract. For simplicity, in native coin.
  function retrieveLentStablecoins(uint256 _tokenId, uint256 _feePercent) internal returns(uint256) {
        uint256 amount = tokenIdToStableCoin[_tokenId];
        uint256 balanceShares = yUSDC.balanceOf(address(this));
        uint256 shareOfShares = amount * balanceShares / totalStableCoin;

        tokenIdToStableCoin[_tokenId] = 0;
        totalStableCoin = totalStableCoin - amount; // amount invested, not active balance

        yUSDC.withdraw(shareOfShares*(10000 - _feePercent)/10000);
        usdc.transfer(address(this), shareOfShares*(10000 - _feePercent)/10000);

        // todo -- update site profits
        contractStablecoinProfit += shareOfShares*_feePercent/10000;

        releaseProfits();

        return shareOfShares*(10000 - _feePercent)/10000;
  }

  function releaseProfits() internal {
      // address profitReceiver
      uint256 profit = contractStablecoinProfit;
      contractStablecoinProfit = 0;
      if ( profit > PROFITRELEASETHRESHOLD) {
          withdrawProfitsFromLending(); // todo--confirm correct function
          (bool res,) = profitReceiver.call{value : profit}("Releasing profits.");
          require(res, "Could not release profits."); // todo -- what about gas fees?
      }
  }

//    function prematureStablecoinWithdrawal(uint256 _tokenId) internal returns(uint256) {
//        uint256 amount = tokenIdToStableCoin[_tokenId];
////        address recipient = ownerOf(_tokenId); // use if want to send stablecoin, not native coin
//        address recipient = address(this);
//        uint256 balanceShares = yUSDC.balanceOf(address(this));
//        uint256 shareOfShares = amount * balanceShares / totalStableCoin;
//
//        tokenIdToStableCoin[_tokenId] = 0;
//        totalStableCoin = totalStableCoin - amount; // amount invested, not active balance
//
//        yUSDC.withdraw(shareOfShares*(10000 - EARLYWITHDRAWALFEEPERCENT)/10000);
//        usdc.transfer(recipient, shareOfShares*(10000 - EARLYWITHDRAWALFEEPERCENT)/10000);
//        return shareOfShares*(10000 - EARLYWITHDRAWALFEEPERCENT)/10000;
//  }

    function withdrawProfitsFromLending() internal {
//        require(msg.sender == owner(), "must be owner");
        uint256 balanceShares = yUSDC.balanceOf(address(this));
        uint256 shareOfShares = contractStablecoinProfit * balanceShares / totalStableCoin;

        totalStableCoin = totalStableCoin - contractStablecoinProfit; // amount invested, not active balance
        contractStablecoinProfit = 0;

        yUSDC.withdraw(shareOfShares);
        usdc.transfer(msg.sender, shareOfShares);

        // emit event
  }


  function lendStableCoin(uint256 _amount) internal {
    usdc.approve(address(yUSDC), _amount);
    yUSDC.deposit(_amount);
  }

  function getStableCoinBalanceGivenId(uint256 _tokenId) internal view returns(uint256) {
    uint256 amount = tokenIdToStableCoin[_tokenId];
    uint256 balanceShares = yUSDC.balanceOf(address(this));
    uint256 shareOfShares = totalStableCoin==0 ? 0 : amount * balanceShares / totalStableCoin;
    return shareOfShares;
 }


  function lendingBalance(uint256 _tokenId) internal view returns(uint256) {
//    uint256 price = yUSDC.getPricePerFullShare();
    uint256 price = 1;
    uint256 balanceShares = yUSDC.balanceOf(address(this));
    uint256 amount = tokenIdToStableCoin[_tokenId];
    return totalStableCoin==0 ? 0 : balanceShares * price * amount / totalStableCoin;
  }

}
