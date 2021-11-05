pragma solidity 0.6.12;

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
//    Mint a token that will purchase dip when BNB goes down to some value
//    Look up best way to sort? on blockchain--algorithm efficiency
//    Purchase stablecoin
//    Loan stablecoin
//    Redeem stablecoin
//    Purchase BNB
//    Upgrade NFT to new graphic
//    1 year limitation on redeeming, 1% penalty + interest + destroy NFT


library UniswapHelpers {

    function _swapExactTokensForETH(uint256 tokenAmount, address tokenContractAddress, address to, address _pair, IUniswapV2Router02 _router, uint256 _swapSlippage) internal  returns (uint256, uint256){
        address[] memory path = new address[](2);
        path[0] = tokenContractAddress; //address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD); // USDT Rinkeby
        path[1] = _router.WETH();

        uint256 minTokensToReceive; // Local scope for many variables
        {
            IUniswapV2Factory _UFactory = IUniswapV2Factory(_router.factory());
            address _tokenPair = _UFactory.getPair(_router.WETH(), tokenContractAddress);
            (uint256 Res0, uint256 Res1,) = IUniswapV2Pair(_tokenPair).getReserves(); // baby doge is Res0

            require(Res1!=0, "No tokens in Res1");
            uint256 ETHPricePerBabyDoge =  (10**18)*Res1/Res0;
            require(ETHPricePerBabyDoge!=0, "ETHPricePerBabyDoge equals zero."); // why? Not dividing by zero anyore
            minTokensToReceive = tokenAmount * (10000 - _swapSlippage);
            minTokensToReceive = minTokensToReceive * ETHPricePerBabyDoge;
            minTokensToReceive = minTokensToReceive / 10**18  / 10000; // ETH TO RECEIVE
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

    function _addLiquidity(uint256 tokenAmount, address contractAddress, IUniswapV2Router02 _router, uint256 newBalance) internal returns(uint256) {
        (uint amountToken,,) =  _router.addLiquidityETH{value: newBalance}(
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

//        console.log(IUniswapV2Pair(_tokenPair).price0CumulativeLast());
//        console.log(IUniswapV2Pair(_tokenPair).price1CumulativeLast());


        uint256 minTokensToReceive;
        {
            IUniswapV2Factory _UFactory = IUniswapV2Factory(_router.factory());
            address _tokenPair = _UFactory.getPair(_router.WETH(), tokenContractAddress);
            (uint256 Res0, uint256 Res1,) = IUniswapV2Pair(_tokenPair).getReserves(); // baby doge is Res0
            require(Res0 !=0, "No tokens in Res0");
            uint256 BabyDogePricePerETH =  ((10**18)*Res0)/Res1; // For 10**18 BabyDoge
            require(BabyDogePricePerETH!=0, "BabyDogePricePerETH equals zero.");
//            minTokensToReceive = ethAmount * (10000 - _swapSlippage) * BabyDogePricePerETH / (10**18) / 10000;
            minTokensToReceive = ethAmount * (10000 - _swapSlippage) * BabyDogePricePerETH;
            minTokensToReceive = minTokensToReceive / (10**18) / 10000;
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


// VRFConsumerBase,
contract BuyTheDipNFT is ERC721, KeeperCompatibleInterface, Ownable  {
    uint256 public tokenCounter;

    // Better to use a struct?
    mapping(uint256 => uint8) public tokenIdToDipLevel; // Number of times NFT has bought the dip
    mapping(uint256 => int256) public tokenIdToDipValue; // Strike Price
    mapping(uint256 => int256) public tokenIdToDipPercent; // Percent Drop
    mapping(uint256 => uint256) public tokenIdToStableCoin; // Amount of USDT purchased
    mapping(uint256 => bool) public tokenIdToIsWaitingToBuy; // True/False if waiting to buy

    uint256 internal fee;
    int256 public smallestDip = 2**127 - 1;
    uint256 swapSlippage = 10000; // full slippage
    uint256 public totalStableCoin = 0;

    uint public immutable interval = 60;
    uint public lastTimeStamp;

//  Rinkeby
    IUniswapV2Router02 router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // testnet
    address factory = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // testnet
    address tokenPair = address(0x0d4a11d5EEaaC28EC3F61d100daF4d40471f1852); // ETH/USDT
    address USDTAddress = address(0x3B00Ef435fA4FcFF5C209a37d1f3dcff37c705aD);

// BSC TESTNET
//    IUniswapV2Router02 router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // testnet
//    address factory = address(0x6725F303b657a9451d8BA641348b6761A6CC7a17); // testnet
//    address tokenPair = address(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // BUSD/BNB

    string public MESSAGE = "NOTHING HAS BEEN UPDATED";
    address public addy;

    AggregatorV3Interface internal priceFeed;

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
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e); // Rinkeby
//        priceFeed = AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331) // Kovan
        lastTimeStamp = block.timestamp;
    }

    function createCollectible(uint32 percentDrop)
        public payable returns (bytes32){
            require (msg.value >= 10**14, "Not Enough BNB--or whatever");
            require(percentDrop < 100, "Percent X must conform to: 10 <= X < 100"); // todo: adjust 10% after testing

            uint256 newItemId = tokenCounter;
            tokenCounter = tokenCounter + 1;
            _safeMint(msg.sender, newItemId);

            tokenIdToDipLevel[newItemId] = 0;
            tokenIdToDipValue[newItemId] = (100 - percentDrop) * getLatestPrice() / 100;
            _setTokenURI(newItemId, tokenURI(newItemId));

            tokenIdToStableCoin[newItemId] = swapETHForTokens(newItemId, msg.value);
            totalStableCoin += tokenIdToStableCoin[newItemId];
            tokenIdToIsWaitingToBuy[newItemId] = true;

            // toDo: Loan out stablecoin (if above threshold?)

            if(newItemId==1) { // temp todo: remove
//                IERC20(USDTAddress).approve(address(router), tokenIdToStableCoin[newItemId]);
////                UniswapHelpers._swapExactTokensForETH(tokenIdToStableCoin[newItemId], USDTAddress, address(this), tokenPair, router, swapSlippage);
//                (ETHSENT, USDTRECEIVED) = UniswapHelpers._swapExactTokensForETH(tokenIdToStableCoin[newItemId], USDTAddress, ownerOf(newItemId), tokenPair, router, swapSlippage);
//                MESSAGE = uint2str(USDTRECEIVED);
                performUpkeepTest();
            }

//             emit requestedCollectible(newItemId);
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, _tokenURI);
    }

    function swapETHForTokens(uint256 _tokenId, uint256 _payment) internal returns (uint256) {
        uint256 ETHSold;
        uint256 tokensBought;
        (ETHSold, tokensBought) = UniswapHelpers._swapEthForTokens(_payment, USDTAddress, address(this), router, swapSlippage);
        require(tokensBought >0, "Error! No tokens bought.");
        return tokensBought;
    }

    // Required to receive ETH
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }


    function reclaimFundsNoInterest(uint256 _tokenId, int256 _dipLevel) public returns(bool) {
        require(msg.sender != ownerOf(_tokenId), "Must be token owner.")

        IERC20(USDTAddress).approve(address(router), tokenIdToStableCoin[_tokenId]);
        (ETHSent, USDTReceived) = UniswapHelpers._swapExactTokensForETH(tokenIdToStableCoin[_tokenId], USDTAddress, ownerOf(_tokenId), tokenPair, router, swapSlippage);

        return true;
    }



    function buyTheDip(uint256 _tokenId, int256 _dipLevel) public onlyKeeper returns(bool) {
        // Confirm price
        require(tokenIdToDipValue[_tokenId] <= getLatestPrice(), 'Price above dipLevel');
        uint256 initialBalance = address(this).balance;
        uint256 ETHSent;
        uint256 USDTReceived;

        IERC20(USDTAddress).approve(address(router), tokenIdToStableCoin[_tokenId]);
        (ETHSent, USDTReceived) = UniswapHelpers._swapExactTokensForETH(tokenIdToStableCoin[_tokenId], USDTAddress, ownerOf(_tokenId), tokenPair, router, swapSlippage);

//        addy = ownerOf(_tokenId);
//        MESSAGE = uint2str(IERC20(USDTAddress).balanceOf(ownerOf(_tokenId)));
//        uint256 finalBalance = address(this).balance; // should equal USDTReceived

        // send ETH to owner.
//        address tokenOwner = ownerOf(_tokenId);

        // handled automatically!
//        uint256 amountReleased = finalBalance - initialBalance;
//        (bool success, ) = tokenOwner.call{value : amountReleased}("Releasing ETH to NFT owner");
//        require(success, "Transfer failed.");

        emit CoinsReleasedToOwner(USDTReceived, block.timestamp);
        tokenIdToStableCoin[_tokenId] = 0;
        tokenIdToIsWaitingToBuy[_tokenId] = false;
//        tokenIdToDipLevel[_tokenId] += 1; // todo -- mechanism somewhere to prevent going above 7
        if (tokenIdToDipLevel[_tokenId] < 7) { tokenIdToDipLevel[_tokenId] += 1; }
        return true;
    }


    function getLatestPrice() public view returns (int) {
        (
            uint80 roundID,
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        // If the round is not complete yet, timestamp is 0
        require(timeStamp > 0, "Round not complete");
        return price;
    }

    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval && smallestDip <= getLatestPrice();
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    // todo: change to external after testing
    function performUpkeep(bytes calldata /* performData */) external override {
        // todo
    }

    function performUpkeepTest() public {
        lastTimeStamp = block.timestamp;
        int256 _smallestDip = 2**127 - 1;
        int256 latestPrice = int256(getLatestPrice()); // todo: reevaluation uint vs int for mappings
        bool dip_bought;

        // this section is triggering issues
        for(uint256 i=0;i<tokenCounter;i++){
            if (tokenIdToIsWaitingToBuy[i] == true) {
                if (tokenIdToDipValue[i] >= latestPrice ){
                    dip_bought = buyTheDip(i, tokenIdToDipValue[i]); // no need to send in second parameter

                    //                    if (dip_bought) {
//                        tokenIdToDipLevel[i]++; // handle where?
//                    }
                }
            }
            else{
                if ( tokenIdToDipValue[i] < _smallestDip) {
                    _smallestDip = tokenIdToDipValue[i];
                }
            }
        }
    }


    function HELPER() public {
        MESSAGE = "IN HELPER";
        string memory SVG = string(abi.encodePacked(
           "%3Csvg xmlns='http://www.w3.org/2000/svg' width='350' height='350'%3E %3Crect width='350' height='350' style='fill:rgb(255,255,255);stroke-width:3;stroke:rgb(0,0,0)' /%3E",
           "%3Ctext x='25' y='25' fill='brown'%3ECurrent ETH Price: %3C/text%3E",
            "%3Ctext x='25' y='55' fill='brown'%3EETH Strike Price: %3C/text%3E",
            "%3Ctext x='25' y='85' fill='brown'%3EUSD Invested: %3C/text%3E",
            "%3Ccircle cx='175' cy='225' r='100' stroke='black' stroke-width='3' fill='white' /%3E",
            "%3Ccircle cx='175' cy='225' r='25' stroke='' stroke-width='0' fill='red' /%3E",
            "Sorry, your browser does not support inline SVG.",
            "%3C/svg%3E"
            ));
        MESSAGE = svgToImageURI(SVG);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string[3] memory _URIs = [
            "https://ipfs.io/ipfs/QmZeMdpQr6CQK75p55hSHRu9wKueMZYngQ4PYTHsTgskoo?filename=BuyTheDipEmpty.jpg",
            "https://ipfs.io/ipfs/QmVVmmaGu7eeASi9YgxAoeAA7BZjwtmiaGcT5hRsTZChVG?filename=BuyTheDipFull.jpg",
            "https://i.picsum.photos/id/53/200/300.jpg?hmac=KbEX4oNyVO15M-9S4xMsefrElB1uiO3BqnvVqPnhPgE"
            ];

        uint8 _dipLevel = tokenIdToDipLevel[_tokenId];
        int256 _dipValue = tokenIdToDipValue[_tokenId];
        int256 _RADIUS = 115;
        uint8 _circleRadius = uint8(_RADIUS*(100 - 100*(getLatestPrice() - _dipValue)/getLatestPrice())/100); // temp, check for negative
        string memory mainImage;

        if (_dipLevel==0){
            mainImage = string(abi.encodePacked(
                "%3Ccircle cx='175' cy='225' r='100' stroke='black' stroke-width='3' stroke-dasharray='15' fill='white' /%3E",
                "%3Ccircle cx='175' cy='225' r='", uint2str(uint256(_circleRadius)) ,"' stroke='' stroke-width='0' fill='red' /%3E"
            ));
        }
        else {
            mainImage = string(abi.encodePacked(
              "%3Cpolygon points='200,110 140,298 290,178 110,178 260,298' ",
              "style='fill:gold;stroke:purple;stroke-width:5;fill-rule:nonzero;' /%3E ",
              "%3Ctext x='55' y='325' fill='brown'%3ECongratulations! You bought the dip. %3C/text%3E"
            ));
        }

        string memory SVG = string(abi.encodePacked(
           "%3Csvg xmlns='http://www.w3.org/2000/svg' width='350' height='350'%3E %3Crect width='350' height='350' style='fill:rgb(255,255,255);stroke-width:3;stroke:rgb(0,0,0)' /%3E",
           "%3Ctext x='25' y='25' fill='brown'%3ECurrent ETH Price: ",
           uint2str(uint256(getLatestPrice())), "%3C/text%3E",
            "%3Ctext x='25' y='55' fill='brown'%3EETH Strike Price: ",
           uint2str(uint256(_dipValue)), "%3C/text%3E",
            "%3Ctext x='25' y='85' fill='brown'%3EUSD Invested: ",
           uint2str(uint256(tokenIdToStableCoin[_tokenId])), " USDT", "%3C/text%3E",
            "%3Ctext x='25' y='115' fill='brown'%3EToken ID: ",
           uint2str(uint256(_tokenId)), "%3C/text%3E",
            mainImage,
            "Sorry, your browser does not support inline SVG.",
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
            return string(
                abi.encodePacked(
                    'data:application/json,',
                    "{'description': 'The NFT limit order that earns money!'",
                    ", 'external_url': 'https://webuythedip.com'",
                    ", 'image': '",
                     imageURI, "'",
                    ", 'name': 'BuyTheDip'",
                    // attributes
                    ", 'attributes': [{'display_type': 'number', 'trait_type': 'Dip Level', 'value': ",
                    tokenIdToDipLevel[_tokenId]==0 ? '0': '1',  " }",
                    ", {'display_type': 'number', 'trait_type': 'Dip Value', 'value': ",
                    uint2str(uint(tokenIdToDipValue[_tokenId])),   " }",
                    "]", // End Attributes
                    "}"
                )
            );
        }
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
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
