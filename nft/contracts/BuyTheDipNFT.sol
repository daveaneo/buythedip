pragma solidity ^0.6.12;
//pragma solidity >= 0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

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


library UniswapHelpers {

    function _swapExactTokensForETH(uint256 tokenAmount, address tokenContractAddress, address to, IUniswapV2Router02 _router, uint256 _swapSlippage) internal  returns (uint256, uint256){

        address[] memory path = new address[](2);
        path[0] = tokenContractAddress; //address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD); // USDT Rinkeby
        path[1] = _router.WETH();

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

        uint256 minTokensToReceive; // Local scope for many variables
        {
            uint256 receivable = _router.getAmountsOut(ethAmount, path)[0];
            minTokensToReceive = receivable * (10000 - _swapSlippage)/10000;
        }

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
    struct Staker {
        address previousOwner;
        uint64 stakeStartTimestamp;
        uint192 moneys;
    }

//    mapping(uint256=>address) public previousOwner;
//    mapping(uint256=>uint256) public stakeStartTimestamp; // we went to disencentivize people who game the system? Maybe don' need to worry
//    mapping(uint256=>uint256) public moneys; // we went to disencentivize people who game the system? Maybe don' need to worry

    mapping(uint256=>Staker) public stakers;

    uint256[] public activeNFTArray;
    uint256 public reservedFundsForInactiveStakers=0; // inactive Stakers
    uint256 public reservedFundsForOwners=0;
    uint256 public ownersCutPercentage=2500; // out of 10,000 (100%)
    uint256 public MinStakingTime = 0; // 60*60*24*7; // 1 week -- todo change times, set function
    address public primaryProfitReceiver;

    event FundsWithdrawnToNFTStaker(
        uint256 amount,
        address indexed to,
        uint256 timestamp
    );

    event FundsWithdrawnToPrimraryProfitReceiver(
        uint256 amount,
        address indexed to,
        uint256 timestamp
    );

    event Unstaked(
        uint256 token,
        address to,
        uint256 timestamp
    );

    // todo -- consider if this will be a pool for one token or all of them
    constructor(address _BuyTheDipNFTAddress) public {
        // set _BuyTheDipNFTAddress
        BTD = BuyTheDipNFT(payable(_BuyTheDipNFTAddress));
        primaryProfitReceiver = msg.sender;
    }

    // todo -- it seems like a bad idea to change state here. Is there going to be an issue for increased cost?
    /** @dev Receive ETH, do accounting for owners/vip cut
      */
    receive() external payable{
        reservedFundsForOwners += ownersCutPercentage*msg.value / 10000;
    }


    /** @dev changes ownersCutPercentage
        @param _newCut -- percentage out of 10000
      */
    function setOwnersCutPercentage(uint256 _newCut) external {
        require((owner() == msg.sender) && (_newCut != ownersCutPercentage) && (_newCut <= 10000), "must be owner, value <= 10000, value => changed");
        ownersCutPercentage = _newCut;
        // todo -- emit event
    }


    /** @dev Adds up all active energy contributed by stakers
        @param _addy -- new address for btd
      */
    function setPrimaryProfitReceiverAddress(address _addy) external {
        require((owner() == msg.sender) && (_addy != primaryProfitReceiver), "must be owner & address must change");
        primaryProfitReceiver = _addy; //BuyTheDipNFT(payable(_addy));
        // todo -- emit event
    }


    /** @dev Adds up all active energy contributed by stakers
        @param _addy -- new address for btd
      */
    function setBTDAdress(address _addy) external {
        require((owner() == msg.sender) && (_addy != address(BTD)), "must be owner & address must change");
        BTD = BuyTheDipNFT(payable(_addy));
    }


    /** @dev Adds up all active energy contributed by stakers
      */
    function getTotalStakingEnergy() public view returns(uint256) {
        // Make sure everyone is flushed.
        uint256 _total = 0;
        for(uint256 i = 0; i < activeNFTArray.length; i++){ // is activeNFTArray.length dynamic here?
            uint256 _id = activeNFTArray[i];
            if(BTD.getProperty(_id, 2) + stakers[_id].stakeStartTimestamp > block.timestamp){
                _total += block.timestamp - stakers[_id].stakeStartTimestamp;
            }
            else {
                _total += BTD.getProperty(_id, 2);
            }
        }
        return _total;
    }

    /** @dev Remove NFT from staking pool, send all profits to owner
        @param _id -- id of NFT. Must be previous owner to call
      */
    function unstake(uint256 _id) external {
        require(msg.sender == stakers[_id].previousOwner, "Not owner."); // dev: Not owner
        require(stakers[_id].stakeStartTimestamp + MinStakingTime <= block.timestamp, "Minimum staking time not met."); // dev: Minimum staking time not met

        withdrawRewards(_id);
//        BTD.approve(stakers[_id].previousOwner, _id); // todo -- necessary?
        BTD.safeTransferFrom(address(this), stakers[_id].previousOwner, _id, "");

        // Remove from array
        for (uint256 i=0; i< activeNFTArray.length; i++) {
            if(activeNFTArray[i]==_id){
                activeNFTArray[i] = activeNFTArray[activeNFTArray.length - 1];
                activeNFTArray.pop();
                break;
            }
        }

        emit Unstaked(_id, stakers[_id].previousOwner, block.timestamp);
        delete stakers[_id];
    }

    
    /** @dev Withdraw native coin, which has been earned as a reward.
        @param _id -- id of NFT. Must be previous owner to call
      */
    function withdrawRewards(uint256 _id) public {
        require(msg.sender == stakers[_id].previousOwner, "Not owner.");
        flushTokenRewardsOf(_id);
        reservedFundsForInactiveStakers -= stakers[_id].moneys;
        uint256 _reward = stakers[_id].moneys;
        stakers[_id].moneys = 0;
        emit FundsWithdrawnToNFTStaker(_reward, stakers[_id].previousOwner, block.timestamp);
        (bool success, ) = address(stakers[_id].previousOwner).call{value : _reward}("Releasing rewards to NFT owner."); // in native token
        require(success, "Transfer failed.");
    }


    /** @dev Withdraw native coined, earned as reward, and set asid for owners/wallet
      */
    function withdrawRewardsForPrimaryProfitReceiver() external {
        require(msg.sender == owner() || msg.sender == primaryProfitReceiver, "Not owner or profit receiver.");
        uint256 _reward = reservedFundsForOwners;
        reservedFundsForOwners = 0;
        (bool success, ) = primaryProfitReceiver.call{value : _reward}("Releasing rewards to primaryProfitReceiver.");
        require(success, "Transfer failed.");
        emit FundsWithdrawnToPrimraryProfitReceiver(_reward, primaryProfitReceiver, block.timestamp);
    }

    /** @dev Returns amount of staking funds available, total minus reserved for specific stakers who have been removed from active staking and from owners
      */
    function getAvailableStakingFunds() public view returns(uint256){
        return (address(this).balance - reservedFundsForInactiveStakers - reservedFundsForOwners);
    }

    /** @dev moves token rewards from the pool and puts it in a separate account for one token. Decreases energy.
        @param _tokenId -- token id
      */
    function flushTokenRewardsOf(uint256 _tokenId) internal returns(bool){
        uint256 _totalStakingEnergy = getTotalStakingEnergy();
        uint256 _rewards = _totalStakingEnergy==0 ? 0: getAvailableStakingFunds() * getActiveEnergyOfToken(_tokenId) / _totalStakingEnergy;
        stakers[_tokenId].moneys += uint192(_rewards);
        reservedFundsForInactiveStakers += _rewards;
        bool popped = false;
        uint256 activeNFTArrayIndex=0;
        // if out of energy
        if(BTD.getProperty(_tokenId, 2) + stakers[_tokenId].stakeStartTimestamp < block.timestamp){
            BTD.setEnergy(_tokenId, 0);
            for(uint256 i=0; i<activeNFTArray.length;i++){
                if(activeNFTArray[i]==_tokenId){
                    activeNFTArray[i] = activeNFTArray[activeNFTArray.length - 1];
                    activeNFTArray.pop();
                    popped = true;
                    break;
                }
            }
        }
        else {
            stakers[_tokenId].stakeStartTimestamp = uint64(block.timestamp);
            BTD.setEnergy(_tokenId, BTD.getProperty(_tokenId, 2) - getActiveEnergyOfToken(_tokenId));
        }
        return popped;
    }

    /** @dev Get energy used since timestamp for specific NFT
        @param _id -- id of NFT. Must be previous owner to call
      */
    function getActiveEnergyOfToken(uint256 _id) public view returns(uint256){
            uint256 _energy;
            if(BTD.getProperty(_id, 2) + stakers[_id].stakeStartTimestamp > block.timestamp){
                _energy = block.timestamp - stakers[_id].stakeStartTimestamp;
            }
            else {
                _energy = BTD.getProperty(_id, 2);
            }
            return _energy;
    }

    /** @dev Flush all staked NFTs that have used up their energy
      */
    function flushInactive() internal {
        bool popped = false;
        uint256 index;

        for(uint256 i = 1; i < activeNFTArray.length + 1; i++){ // is activeNFTArray.length dynamic here?
            if(BTD.getProperty(activeNFTArray[i], 2) + stakers[i].stakeStartTimestamp < block.timestamp){
                index = i - 1;
                // Here, we shift the index because of [] popping
                // Being sure not to go beyond the array or miss
                if(flushTokenRewardsOf(activeNFTArray[index])){
                      i -= 1; // start with 1 to avoid underflow
                }
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
            if(stakers[i].previousOwner==_addy){
                total +=1;
            }
        }

        uint256[] memory owned = new uint256[](total);
        uint256 count=0;

        // Two cycles are needed because of inability to push integers to memory array
        for(uint256 i=0;i<_tokenCounter;i++){
            if(count>=total){ break; }
            if(stakers[i].previousOwner == _addy){
                owned[count]=i;
                count +=1;
            }
        }
        return owned;
    }



    /** @dev Upkeep when receiving NFTs
      */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external override returns(bytes4){
          require(msg.sender==address(BTD), string(abi.encodePacked(msg.sender)));
          require(BTD.qualifiesForStaking(_tokenId)==true,"Not qualified for staking");

          stakers[_tokenId].stakeStartTimestamp = uint64(block.timestamp);
          stakers[_tokenId].previousOwner = _from; //tx.origin; //msg.sender;
          activeNFTArray.push(_tokenId);
        //        bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
        return this.onERC721Received.selector;
    }
}

contract BuyTheDipNFT is ERC721, KeeperCompatibleInterface, Ownable  {
    uint256 public tokenCounter;

    mapping(uint256 => uint256) public tokenIdToPackedData; // compressed data for NFT

    // todo -- could pack these differently (not 256). Pros and cons?
    struct Data {
        uint256 dipValue;
        uint256 stableCoinAmount;
        uint256 energy;
        uint256 dipPercent;
        uint256 dipLevel;
        uint256 isWaitingToBuy;
    }
    enum DataProperties {DipValue, StableCoinAmount, Energy, DipPercent, DipLevel, IsWaitingToBuy}

    // todo -- set some to private?
    uint256 public highestDip = 0;
    uint256 public swapSlippage = 10000; // full slippage
    uint256 public totalStableCoin = 0;
    uint256 public contractStableCoinProfit;
    address public profitReceiver;

    uint256 private checkUpkeepInterval = 60;
    uint256 private lastTimeStamp;
    uint256 private MINCOINDEPOSIT = 10**14;
    uint256 private EARLYWITHDRAWALFEEPERCENT = 300; // (out of 100*100)
    uint256 private NORMALWITHDRAWALFEEPERCENT = 100; // (out of 100*100)
    uint256 private MINTFEE = 10**12;
    uint256 private STABLECOINDUSTTHRESHOLD = 10**6/10; //10 cents
    uint256 private PROFITRELEASETHRESHOLD = 10**16;


    // todo --- consider creating: minDipPercent ( createCollectible )

    enum ConfigurableVariables { SwapSlippage,
        CheckUpkeepInterval, MinCoinDeposit, EarlyWithdrawalFeePercent, NormalWithdrawalFeePercent,
        MintFee, StableCoinDustThreshold, ProfitReleaseThreshold, ContractStableCoinProfit }


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


    // Swap Routers
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

    // Chainlink Price feeds
//    AggregatorV3Interface internal priceFeed;
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419) // ETH/USD, Ethereum mainnet
    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); // ETH/USD, Rinkeby (Ethereum testnet)
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331); // ETH/USD, Kovan (Ethereum testnet
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526); // BNB/USD, bsc testnet
//    AggregatorV3Interface internal priceFeed = AggregatorV3Interface(0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE); // BNB/USD, bsc mainnet


//    address public addy;

    event CoinsReleasedToOwner(
        uint256 amountETH,
        uint256 valueInUSD,
        uint256 indexed tokenId,
        address indexed addy,
        uint256 date
    );

    event CoinsReleasedToProfitReceiver(
        uint256 amountETH,
        uint256 valueInUSD,
        address indexed addy,
        uint256 date
    );

    event CollectibleCreated(
        uint256 _id,
        uint256 data,
        uint256 date
    );

    event NFTBurned(
        uint256 _id,
        address burner,
        uint256 date
    );

    event Received(
        address sender,
        uint256 amount
    );

    event ReleaseInformation(
        uint256 InformationA,
        uint256 InformationB,
        uint256 InformationC
    );


    modifier onlyKeeper {
       require(true);
       //require(msg.sender == owner); // ToDo: modify
      _;
   }

    /** @dev Packs 6 uints from data structure into 1 uint to save space (96, 96, 32, 8, 8, 8) -> 256
        @param _myData -- data structure holding attributes of NFT
    */
    function packDataStructure(Data memory _myData) internal pure returns (uint256){
        return packData(_myData.dipValue, _myData.stableCoinAmount, _myData.energy, _myData.dipPercent, _myData.dipLevel, _myData.isWaitingToBuy);
    }

    // OLDER--Packs 6 uints into 1 uint to save space (90, 90, 32, 8, 3, 1) -> 256
    /** @dev Packs 6 uints into 1 uint to save space (96, 96, 32, 8, 8, 8) -> 256
        @param _dipValue -- strike price, uint96
        @param _stableCoinAmount -- amount of stablecoin locked in NFT, uint96
        @param _energy -- energy (time permitted to stake), uint32
        @param _dipPercent -- percent drop to set strike price, uint8
        @param _dipLevel -- level (number of times dip has been bought), "uint8"
        @param _isWaitingToBuy -- true if waiting to buy dip, false if dip bought and not redipped, uint8
      */
    function packData(uint256 _dipValue, uint256 _stableCoinAmount, uint256 _energy, uint256 _dipPercent, uint256 _dipLevel, uint256 _isWaitingToBuy) internal pure returns (uint256){
        uint256 count = 0;
        uint256 ret = _dipValue;
        count += 96;

        ret |= _stableCoinAmount << count;
        count += 96;

        ret |= _energy << count;
        count += 32;

        ret |= _dipPercent << count;
        count += 8;

        ret |= _dipLevel << count;
        count += 8;

        ret |= _isWaitingToBuy << count;
        count += 8;

        return ret;
    }


    /** @dev Unpacks 1 uints into 3 uints; (256) -> (90, 90, 32, 8, 3, 1)
        @param _id -- NFT id, which will pull the 256 bit encoding of _dipValue, _stableCoinAmount, _energy, _dipPercent, _dipLevel, and _isWaitingToBuy
      */
    function unpackData(uint256 _id) internal view returns (Data memory){
//        uint256 _myData = tokenIdToPackedData[_id];
        return _unpackData(tokenIdToPackedData[_id]);
    }


    /** @dev Unpacks 1 uints into 3 uints; (256) -> (90, 90, 32, 8, 3, 1)
        @param _myData -- 256 bit encoding of _dipValue, _stableCoinAmount, _energy, _dipPercent, _dipLevel, and _isWaitingToBuy
      */
    function _unpackData(uint256 _myData) internal pure returns (Data memory){

        uint256 _dipValue = uint256(uint96(_myData));
        uint256 _stableCoinAmount = uint256(uint96(_myData >> 96));
        uint256 _energy = uint256(uint32(_myData >> 192));

        uint256 _dipPercent = uint256(uint8(_myData >> 224));
        uint256 _dipLevel = uint256(uint8(_myData >> 232));
        uint256 _isWaitingToBuy = uint256(uint8(_myData >> 240));

        return Data(_dipValue, _stableCoinAmount, _energy, _dipPercent, _dipLevel, _isWaitingToBuy);
    }

//    function verifyPacking() public view returns(bool){
//        uint256 compressed = packData(1,2,3,4,5,6);
//        Data memory _myData = _unpackData(compressed);
//        if(
//            _myData.dipValue == 1 &&
//            _myData.stableCoinAmount == 2 &&
//            _myData.energy == 3 &&
//            _myData.dipPercent == 4 &&
//            _myData.dipLevel == 5 &&
//            _myData.isWaitingToBuy == 6
//        ) { return true;}
//        else {return false;}
//    }

    constructor()
    public
    ERC721("WeBuyTheDip", "DIP")
    {
        tokenCounter = 0;
        profitReceiver = owner();
        lastTimeStamp = block.timestamp;
    }


    // todo: Create liquidity pool for USDC on pancakeswap BSC testnet
    function createCollectible(uint256 percentDrop)
        public payable returns (bytes32){
            require (msg.value >= MINCOINDEPOSIT + MINTFEE); // dev: Not enough native coin
            require(percentDrop < 100, "Percent X must conform to: 10 <= X < 100"); // todo: adjust 10% after testing
            updateAllBalances(); // todo --consider creating counterBalance
            _safeMint(msg.sender, tokenCounter);
            // MINTFEE and msg.value gets converted to stablecoin and sent to vault
            (, uint256 stableCoinReceived) = UniswapHelpers._swapEthForTokens(msg.value, StableCoinAddress, address(this), router, swapSlippage);

            Data memory _myData = Data( {
                dipValue:(100 - percentDrop) * getLatestPrice() / 100,
                stableCoinAmount:(msg.value - MINTFEE) * stableCoinReceived/ (msg.value),
                energy:0,
                dipPercent:percentDrop,
                dipLevel:0,
                isWaitingToBuy:1
            });

            tokenIdToPackedData[tokenCounter] = packDataStructure(_myData);
            contractStableCoinProfit += MINTFEE * stableCoinReceived/ (msg.value);
            require(_myData.stableCoinAmount > 0, "Error! No tokens bought.");
            lendStableCoin(stableCoinReceived);

            if(_myData.dipValue > highestDip){
                highestDip = _myData.dipValue;
            }

            totalStableCoin += stableCoinReceived;
            _setTokenURI(tokenCounter, tokenURI(tokenCounter));
            emit CollectibleCreated(tokenCounter, tokenIdToPackedData[tokenCounter], block.timestamp);

            tokenCounter = tokenCounter + 1;
            if (contractStableCoinProfit > PROFITRELEASETHRESHOLD) {
                releaseOwnerProfits(); // for contract, not NFTHolder
            }
    }

    // todo: combine shared features from createCollectible
    /** @dev Buying the dip again on existing NFTs
      */
    function redip(uint256 _tokenId) public payable returns (bytes32) {
        // Constrain deposit to range based on previous deposits? Or always absolute minimum?
        Data memory _myData = unpackData(_tokenId);

        require (msg.value >= MINCOINDEPOSIT, "Not Enough BNB--or whatever");
        require(_myData.isWaitingToBuy == 0, "already in process of buying dip.");

        // update balances to keep lent funds fair
        // no need to refresh _myData, as we are resetting StableCoinAmount
        updateAllBalances();

        _myData.dipValue = (100 - _myData.dipPercent) * getLatestPrice() / 100;
        _setTokenURI(_tokenId, tokenURI(_tokenId));

        (, uint256 stableCoinReceived) = UniswapHelpers._swapEthForTokens(msg.value, StableCoinAddress, address(this), router, swapSlippage);
        _myData.stableCoinAmount = (msg.value - MINTFEE) * stableCoinReceived/ (msg.value);
        contractStableCoinProfit += MINTFEE * stableCoinReceived/ (msg.value);

        require(_myData.stableCoinAmount > 0, "Error! No tokens bought.");

        lendStableCoin(stableCoinReceived);
        totalStableCoin += stableCoinReceived;

        _myData.isWaitingToBuy = 1;

        if(_myData.dipValue > highestDip){
            highestDip = _myData.dipValue;
        }

        tokenIdToPackedData[_tokenId] = packDataStructure(_myData);
        // todo Emit LimitOrderCreated, Redip, ...
    }


    function qualifiesForStaking(uint256 _tokenId) external view returns(bool) {
        Data memory _myData = unpackData(_tokenId);
        return _myData.isWaitingToBuy==0 && _myData.energy > 0;
    }

//    // todo --replace with getProperty in dipStaking
//    function getEnergy(uint256 _tokenId) external view returns(uint256) {
//        Data memory _myData = unpackData(_tokenId);
//        return _myData.energy;
//    }

    function getProperty(uint256 _tokenId, uint256 property) external view returns(uint256) {
        Data memory _myData = unpackData(_tokenId);
        require(property<6);
//        enum DataProperties {DipValue, StableCoinAmount, Energy, DipPercent, DipLevel, IsWaitingToBuy};
        uint256 value = 0;
        if(property==0){
            value = _myData.dipValue;
        }
        else if(property==1){
            value = _myData.stableCoinAmount;
        }
        else if(property==2){
            value = _myData.energy;
        }
        else if(property==3){
            value = _myData.dipPercent;
        }
        else if(property==4){
            value = _myData.dipLevel;
        }
        else if(property==5){
            value = _myData.isWaitingToBuy;
        }
        return value;
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


    // todo -- consider creating a negative balance to avoid updating everyone elses -- not a simple calculation
    // todo -- ie, a new token is minted, and instead of updating every single balance, the amount it would gain is tracked and reversed
    /** @dev Update balances with new interest values
      */
    function updateAllBalances() internal {
        uint256 _addedTokens;
        uint256 _newTotal = totalStableCoin;
        uint256 _newIndividialBalance;
        Data memory _myData;

        // update contractStableCoinProfit
        _newIndividialBalance = totalStableCoin==0 ? 0 : contractStableCoinProfit * yUSDC.balanceOf(address(this)) / totalStableCoin;
        _addedTokens = _newIndividialBalance > _myData.stableCoinAmount ? _newIndividialBalance - _myData.stableCoinAmount : 0;
        if(_addedTokens > STABLECOINDUSTTHRESHOLD ){
            contractStableCoinProfit = _newIndividialBalance;
            _newTotal += _addedTokens;
        }

        for(uint256 i = 0; i < tokenCounter;i++){
            _myData = unpackData(i);
            if(_myData.isWaitingToBuy==1){
                _newIndividialBalance = getStableCoinBalanceGivenId(i);
                // todo -- will thise ever be negative? If so, ramifications?
                _addedTokens = _newIndividialBalance > _myData.stableCoinAmount ? _newIndividialBalance - _myData.stableCoinAmount : 0;
                if(_addedTokens > STABLECOINDUSTTHRESHOLD ){
                    _myData.stableCoinAmount = _newIndividialBalance;
                    _newTotal += _addedTokens;
                    tokenIdToPackedData[i] = packDataStructure(_myData);
                }
            }
        }
        totalStableCoin = _newTotal;
    }

    /** @dev Functions like breaking a piggy bank. Burns NFT and retrieves contents, subjec to a early-withdrawal fee
        @param _tokenId -- 256 bit encoding of _dipValue, _stableCoinAmount, _energy, _dipPercent, _dipLevel, and _isWaitingToBuy
      */
    function destroyAndRefund(uint256 _tokenId) public {
        require(msg.sender == ownerOf(_tokenId), "Must be token owner.");
        Data memory _myData = unpackData(_tokenId);

        if (getLatestPrice() <= _myData.dipValue){
            buyTheDip(_tokenId);
        }
        else {
            // get stablecoin amount after penalty
            uint256 _withdrawal = retrieveLentStablecoins(_tokenId, EARLYWITHDRAWALFEEPERCENT);
            if(_withdrawal > 0) {
                usdc.approve(address(router), _withdrawal);
                (uint256 stableCoinSent, uint256 ETHReceived) = UniswapHelpers._swapExactTokensForETH(_withdrawal, StableCoinAddress, ownerOf(_tokenId), router, swapSlippage);
                emit CoinsReleasedToOwner(ETHReceived, stableCoinSent, _tokenId, ownerOf(_tokenId), block.timestamp);
            }
        }
        NFTBurned(_tokenId, ownerOf(_tokenId), block.timestamp);
        safeTransferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _tokenId, "burn NFT");
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


    function buyTheDip(uint256 _tokenId) internal {
        // Confirm price
        Data memory _myData = unpackData(_tokenId);
        require(getLatestPrice() <= _myData.dipValue, 'Price above dipLevel');

        uint256 _withdrawal = retrieveLentStablecoins(_tokenId, NORMALWITHDRAWALFEEPERCENT);
        usdc.approve(address(router), _withdrawal);
        (uint256 stableCoinSent, uint256 ETHReceived) = UniswapHelpers._swapExactTokensForETH(_withdrawal, StableCoinAddress, ownerOf(_tokenId), router, swapSlippage);

        emit CoinsReleasedToOwner(ETHReceived, stableCoinSent, _tokenId, ownerOf(_tokenId), block.timestamp);
        if (_myData.dipLevel < 7) { _myData.dipLevel += 1; }

        _myData.energy += 86400 + _myData.stableCoinAmount * _myData.dipLevel  * (_myData.dipPercent **2) / 10000; // todo -- choose energy formula
        _myData.stableCoinAmount = 0;
        _myData.isWaitingToBuy = 0;
        tokenIdToPackedData[_tokenId] = packDataStructure(_myData);
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
        upkeepNeeded = (block.timestamp - lastTimeStamp) > checkUpkeepInterval && getLatestPrice() <= highestDip;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function checkUpkeepView(bytes calldata /* checkData */) external view returns (bool upkeepNeeded) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > checkUpkeepInterval && getLatestPrice() <= highestDip;
        return upkeepNeeded;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        // todo -- update
        performUpkeepTest(); // Putting this here to make the functionality more legit. It is still to develop fully
    }

    function performUpkeepTest() public {
        lastTimeStamp = block.timestamp;
        uint256 latestPrice = getLatestPrice();
        bool dipBought = false;
        Data memory _myData;

        for(uint256 i=0;i<tokenCounter;i++){
            _myData = unpackData(i);
            if (_myData.isWaitingToBuy == 1 && latestPrice <= _myData.dipValue) {
                buyTheDip(i);
                dipBought = true;
            }
        }

        if(dipBought){
            uint256 _highestDip = 0;
            for(uint256 i=0;i<tokenCounter;i++){
                _myData = unpackData(i);
                if ( _myData.dipValue > highestDip) {
                    highestDip = _myData.dipValue;
                }
            }
            highestDip =  _highestDip;
        }
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        Data memory _myData = unpackData(_tokenId);

        uint256 _RADIUS = 78; // 80 - 2
        uint256 _latestPrice = uint256(getLatestPrice());
        uint256 _circleRadius;
        if (_myData.isWaitingToBuy==1) {
            _circleRadius = _RADIUS;
        }
        else {
            _circleRadius = (_latestPrice > ((_myData.dipValue)*100/(100 - _myData.dipPercent))) ? 0 : uint256(_RADIUS*(100 - 100*(_latestPrice - _myData.dipValue)/_latestPrice)/100); // temp, check for negative
        }
        string memory mainImage;
        mainImage = string(abi.encodePacked(
            "%3Ccircle style='fill:%23ffffff;stroke:%230045bb;stroke-width:1.38;stroke-linejoin:round;stroke-opacity:1;stroke-miterlimit:4;stroke-dasharray:none' id='path846' cx='175' cy='200' r='100' /%3E ",
            "%3Ccircle style='fill:%23ffffff;stroke:%23000000;stroke-width:4;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:0.32' id='path846-5' cx='175' cy='200' r='80' /%3E",
            "%3Ccircle cx='175' cy='200' r='", uint2str(_circleRadius) ,"' stroke='' stroke-width='0' fill='green' /%3E"
         ));

        if (_myData.isWaitingToBuy==0) { // not waiting to buy, ie already bought the dip
            mainImage = string(abi.encodePacked(mainImage,
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
           "%3Ctext x='175' y='60' font-weight='normal' fill='brown'%3E$", uint2str(uint256(_myData.dipValue), 8, 2), "%3C/text%3E",
                // Stable Coin Invested (conversion)
           "%3Ctext x='35' y='75'  font-weight='bold' fill='brown'%3EUSDC Balance:%3C/text%3E"
            ));

            // Stack-deepness error, so breaking this up
            SVG = string(abi.encodePacked(SVG, // todo -- this is showing up incorrectly. consider using _myData.stableCoin (or whatever), and also see why the below is failing
           "%3Ctext x='175' y='75' font-weight='normal' fill='brown'%3E$", uint2str(lendingBalance(_tokenId), 6, 2), " %3C/text%3E",
                // Energy
           "%3Ctext x='35' y='90' font-weight='bold' fill='brown'%3EEnergy:%3C/text%3E",
           "%3Ctext x='175' y='90' font-weight='normal' fill='brown'%3E", uint2str(_myData.energy), "%3C/text%3E",

           ///// Top Middle
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

        return formatTokenURI(_tokenId, svgToImageURI(SVG));
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
        Data memory _myData = unpackData(_tokenId);
        require(_energy <= _myData.energy, "Can't increase energy"); // set equal??? check in other places
        _myData.energy = _energy;
        tokenIdToPackedData[_tokenId] = packDataStructure(_myData);
    }


    function formatTokenURI(uint256 _tokenId, string memory imageURI) public view returns (string memory) {
        Data memory _myData = unpackData(_tokenId);
        string memory json_str = string(abi.encodePacked(
            '{"description": "The NFT limit order that earns money!"',
            ', "external_url": "https://webuythedip.com"',
            ', "image": "',
             imageURI, '"',
            ', "name": "BuyTheDip"',
            // attributes
            ', "attributes": [{"display_type": "number", "trait_type": "Dip Level", "value": ',
            uint2str(uint256(_myData.dipLevel)),   ' }'
        ));
        json_str = string(abi.encodePacked(json_str,
            ', {"display_type": "number", "trait_type": "Strike Price", "value": ',
            uint2str(uint256(_myData.dipValue)),   ' }',
            ', {"display_type": "number", "trait_type": "USDC Balance", "value": ',
            uint2str(uint256(_myData.stableCoinAmount)),   ' }',
                ', {"display_type": "number", "trait_type": "Energy", "value": ',
            uint2str(uint256(_myData.energy)),   ' }',
            ']', // End Attributes
            '}'
        ));

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(json_str)));


//        return string(
//            abi.encodePacked(
//                "data:application/json;base64,",
//                Base64.encode(
//                    string(
//                        abi.encodePacked(
//                            '{"description": "The NFT limit order that earns money!"',
//                            ', "external_url": "https://webuythedip.com"',
//                            ', "image": "',
//                             imageURI, '"',
//                            ', "name": "BuyTheDip"',
//                            // attributes
//                            ', "attributes": [{"display_type": "number", "trait_type": "Dip Level", "value": ',
//                            uint2str(uint256(_myData.dipLevel)),   ' }',
//                            ', {"display_type": "number", "trait_type": "Strike Price", "value": ',
//                            uint2str(uint256(_myData.dipValue)),   ' }',
//                            ', {"display_type": "number", "trait_type": "USDC Balance", "value": ',
//                            uint2str(uint256(_myData.stableCoinAmount)),   ' }',
//                                ', {"display_type": "number", "trait_type": "Energy", "value": ',
//                            uint2str(uint256(_myData.energy)),   ' }',
//                            ']', // End Attributes
//                            '}'
//                        )
//                    )
//                )
//            )
//        );
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



    /////////////////////////////////////////////
    /////////// Configuration Helpers ///////////
    /////////////////////////////////////////////

  function setProfitReceiver(address _newReceiver) external {
    require(msg.sender == owner() && _newReceiver != profitReceiver, "only owner can change configuration");
    profitReceiver = _newReceiver;
  }

  function changeConfiguration(uint256 _enumValue, uint256 _newValue) external {
    require(_enumValue < 8, "No such configuration data.");
    require(msg.sender == owner(), "only owner can change configuration");

    ConfigurableVariables parameter = ConfigurableVariables(_enumValue);

    if(parameter == ConfigurableVariables.SwapSlippage){
        require(_newValue<10000);
        swapSlippage = _newValue;
    }
    else if(parameter == ConfigurableVariables.CheckUpkeepInterval){
        checkUpkeepInterval = _newValue;
    }
    else if(parameter == ConfigurableVariables.MinCoinDeposit){
        MINCOINDEPOSIT = _newValue;
    }
    else if(parameter == ConfigurableVariables.EarlyWithdrawalFeePercent){
        require(_newValue<10000); // todo -- confirm percentage is out of 10,000
        EARLYWITHDRAWALFEEPERCENT = _newValue;
    }
    else if(parameter == ConfigurableVariables.NormalWithdrawalFeePercent){
        require(_newValue<10000); // todo -- confirm percentage is out of 10,000
        NORMALWITHDRAWALFEEPERCENT = _newValue;
    }
    else if(parameter == ConfigurableVariables.MintFee){
        MINTFEE = _newValue;
    }
    else if(parameter == ConfigurableVariables.StableCoinDustThreshold){
        STABLECOINDUSTTHRESHOLD = _newValue;
    }
    else if(parameter == ConfigurableVariables.ProfitReleaseThreshold){
        PROFITRELEASETHRESHOLD = _newValue;
    }
  }

  function getConfiguration(uint256 _enumValue) external view returns(uint256) {
    require(_enumValue < 8, "No such configuration data.");

    ConfigurableVariables parameter = ConfigurableVariables(_enumValue);
    uint256 _ret;

    if(parameter == ConfigurableVariables.SwapSlippage){
        _ret = swapSlippage;
    }
    else if(parameter == ConfigurableVariables.CheckUpkeepInterval){
        _ret = checkUpkeepInterval;
    }
    else if(parameter == ConfigurableVariables.MinCoinDeposit){
        _ret = MINCOINDEPOSIT;
    }
    else if(parameter == ConfigurableVariables.EarlyWithdrawalFeePercent){
        _ret = EARLYWITHDRAWALFEEPERCENT;
    }
    else if(parameter == ConfigurableVariables.NormalWithdrawalFeePercent){
        _ret = NORMALWITHDRAWALFEEPERCENT;
    }
    else if(parameter == ConfigurableVariables.MintFee){
        _ret = MINTFEE;
    }
    else if(parameter == ConfigurableVariables.StableCoinDustThreshold){
        _ret = STABLECOINDUSTTHRESHOLD;
    }
    else if(parameter == ConfigurableVariables.ProfitReleaseThreshold){
        _ret = PROFITRELEASETHRESHOLD;
    }
      return _ret;
  }



    /////////////////////////////
    /////////// yUDSC ///////////
    /////////////////////////////

//    function withdrawProfitsFromLending() internal returns(uint256){
//        uint256 balanceShares = yUSDC.balanceOf(address(this));
//        uint256 shareOfShares = contractStableCoinProfit * balanceShares / totalStableCoin;
//
//        totalStableCoin = totalStableCoin - contractStableCoinProfit; // amount invested, not active balance
//        contractStableCoinProfit = 0;
//
//        yUSDC.withdraw(shareOfShares);
//        usdc.transfer(address(this), shareOfShares);
//        return shareOfShares;
//    }


    // Profits are going to be sent to the staking contract. For simplicity, in native coin.
  function retrieveLentStablecoins(uint256 _tokenId, uint256 _feePercent) internal returns(uint256) {
        Data memory _myData = unpackData(_tokenId);
        uint256 balanceShares = yUSDC.balanceOf(address(this)); //yUSDC.wei_balance => ???
        uint256 shareOfShares = _myData.stableCoinAmount * balanceShares / totalStableCoin;

        // todo -- consider implimenting countershares, here
        // idea: create a counterBalance amount when token is funded (minted or redipped)
      // this amount is shareOfShares snapshot at time of funding
      // and subtracted from future shareOfShares amounts
      // this avoids recalculating everyone's transactions

        _myData.stableCoinAmount = 0;
        tokenIdToPackedData[_tokenId] = packDataStructure(_myData);

        require(totalStableCoin >= shareOfShares, "critical error: shareOfShares is oversized");
        totalStableCoin = totalStableCoin - shareOfShares*(10000 - _feePercent)/10000; // _myData.stableCoinAmount invested, not active balance to-- this should probably be less

        yUSDC.withdraw(shareOfShares*(10000 - _feePercent)/10000);
        usdc.transfer(address(this), shareOfShares*(10000 - _feePercent)/10000);

        contractStableCoinProfit += shareOfShares*_feePercent/10000;

        if (contractStableCoinProfit > PROFITRELEASETHRESHOLD) {
            releaseOwnerProfits(); // for contract, not NFTHolder
        }

        return shareOfShares*(10000 - _feePercent)/10000;
  }

    // todo -- make internal after testing
  function releaseOwnerProfits() internal {
        require(contractStableCoinProfit > PROFITRELEASETHRESHOLD, "Stablecoin profit below threshold.");

        // todo --review for reentrancy attack
        uint256 profit = contractStableCoinProfit;
        // get USDC
        uint256 _withdrawal; { // = withdrawProfitsFromLending();
            uint256 balanceShares = yUSDC.balanceOf(address(this));
            uint256 shareOfShares = contractStableCoinProfit * balanceShares / totalStableCoin;

            totalStableCoin = totalStableCoin - contractStableCoinProfit; // amount invested, not active balance
            contractStableCoinProfit = 0;

            yUSDC.withdraw(shareOfShares);
            usdc.transfer(address(this), shareOfShares);
            _withdrawal =  shareOfShares;
        }

        usdc.approve(address(router), _withdrawal);
        (uint256 stableCoinSent, uint256 ETHReceived) = UniswapHelpers._swapExactTokensForETH(_withdrawal, StableCoinAddress, profitReceiver, router, swapSlippage);
        emit CoinsReleasedToProfitReceiver(ETHReceived, stableCoinSent, profitReceiver, block.timestamp);
  }



    function lendStableCoin(uint256 _amount) internal {
        usdc.approve(address(yUSDC), _amount);
        yUSDC.deposit(_amount);
    }


    function getStableCoinBalanceGivenId(uint256 _tokenId) internal view returns(uint256) {
        Data memory _myData = unpackData(_tokenId);
        uint256 balanceShares = yUSDC.balanceOf(address(this));
        return totalStableCoin==0 ? 0 : _myData.stableCoinAmount * balanceShares / totalStableCoin;
    }

  function lendingBalance(uint256 _tokenId) public view returns(uint256) {
//    uint256 price = yUSDC.getPricePerFullShare();
    Data memory _myData = unpackData(_tokenId);
    uint256 price = 1;
    uint256 balanceShares = yUSDC.balanceOf(address(this));
    return totalStableCoin==0 ? 0 : balanceShares * price * _myData.stableCoinAmount / totalStableCoin; // todo --determine info here
  }

//  function releaseLendingInfo(uint256 _tokenId) public returns(uint256) {
////    uint256 price = yUSDC.getPricePerFullShare();
//    Data memory _myData = unpackData(_tokenId);
//    uint256 price = 1;
//    uint256 balanceShares = yUSDC.balanceOf(address(this));
//    emit ReleaseInformation(balanceShares, yUSDC.getPricePerFullShare(), balanceShares * price * _myData.stableCoinAmount / totalStableCoin);
//    return totalStableCoin==0 ? 0 : balanceShares * price * _myData.stableCoinAmount / totalStableCoin; // todo --determine info here
//  }


} // end BuyTheDip Contract
