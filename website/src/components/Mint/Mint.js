import React, { Component } from "react";
import "./Mint.css";
import Web3 from "web3";
//import fs from "fs";
import abiBTD from "../../abi/BuyTheDipNFT.json";
import Contract from "web3-eth-contract";

//const contractJson = fs.readFileSync("../../abi/BuyTheDipNFT.json");

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};

//const abi = JSON.parse(BuyTheDipNFT);
//const abi = {
//  "abi" : "blabla",
//  "first_name"  :  "Sammy",
//  "last_name"   :  "Shark",
//  "online"      :  true
//}
//const abi = [{"name":"NewExchange","inputs":[{"type":"address","name":"token","indexed":true},{"type":"address","name":"exchange","indexed":true}],"anonymous":false,"type":"event"},{"name":"initializeFactory","outputs":[],"inputs":[{"type":"address","name":"template"}],"constant":false,"payable":false,"type":"function","gas":35725},{"name":"createExchange","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"token"}],"constant":false,"payable":false,"type":"function","gas":187911},{"name":"getExchange","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"token"}],"constant":true,"payable":false,"type":"function","gas":715},{"name":"getToken","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"address","name":"exchange"}],"constant":true,"payable":false,"type":"function","gas":745},{"name":"getTokenWithId","outputs":[{"type":"address","name":"out"}],"inputs":[{"type":"uint256","name":"token_id"}],"constant":true,"payable":false,"type":"function","gas":736},{"name":"exchangeTemplate","outputs":[{"type":"address","name":"out"}],"inputs":[],"constant":true,"payable":false,"type":"function","gas":633},{"name":"tokenCount","outputs":[{"type":"uint256","name":"out"}],"inputs":[],"constant":true,"payable":false,"type":"function","gas":663}]

console.log(abiBTD)

let _tokenId = 1;
let _dipLevel = 1; //tokenIdToDipLevel[_tokenId];
let _strikePrice = 2500; //uint256(tokenIdToDipValue[_tokenId]);
let _RADIUS = 78; // 80 - 2
let _latestPrice = 4700; //let(getLatestPrice());
let _circleRadius = 0;
let _lendingBalance = 1234;
let _energy = 0;
const buyTheDipAddress = "0x4E0952fAbC59623c57793D4BE3dDb8fAaA11E27A";
const dipStakingAddress = "0xa3CCd7d5Fc57960a67620985e75EaB232D22E2be";
let ENDPOINT_ETH =
  "https://rinkeby.infura.io/v3/415d8f8ad8bf4a179cabd397a48d08ce";
//let ENDPOINT_ETH="https://rinkeby.infura.io/v3/415d8f8ad8bf4a179cabd397a48d08ce";
//let ENDPOINT_MAINNET_ETH="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/rinkeby";
//let ENDPOINT_TESTNET_ROPSTEN_ETH="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/ropsten";
//let ENDPOINT_TESTNET_BSC="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/bsc/testnet";
//let ENDPOINT_MAINNET_BSC="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/bsc/mainnet";
let ENDPOINT_WSS_ETH_TESTNET="wss://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/rinkeby/ws";
let ENDPOINT_WSS_BSC_TESTNET="wss://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/bsc/testnet/ws";

//todo-- create getMinABI function or use existing function to get ABI

Contract.setProvider(ENDPOINT_WSS_ETH_TESTNET);

class Mint extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
      ether: 0,
      percent: 0,
    };
  }

  contract = new Contract(abiBTD, buyTheDipAddress, {
    from: this.props.account,
  });

  mintNFT(ether, percentage) {
    this.contract.methods
      .createCollectible(percentage)
      .send({ from: this.props.account, value: ether })
      .then((balance) => {
        console.log(balance);
      });
  }

  render() {
    return (
      <section className="hero-section" id="mint">
        <div className="container">
          <label for="CoinAmount">ETH to add:</label>
          <input
            onChange={(event) => this.setState({ ether: event.target.value })}
            type="number"
            id="CoinAmount"
            name="CoinAmount"
            min="0.1"
            step="0.01"
          />
          <label for="DipPercent">Percent Dip to Repurchase:</label>
          <input
            onChange={(event) => this.setState({ percent: event.target.value })}
            type="number"
            id="DipPercent"
            name="DipPercent"
            min="10"
            step="1"
            max="100"
          />

          {/* PREVIEW OF NFT */}
          <div className="NFT-image-container">
            <svg xmlns="http://www.w3.org/2000/svg" width="350" height="350">
              <rect width="350" height="350" className="NFT-box" />{" "}
              {/* style='fill:rgb(255,255,255);stroke-width:3;stroke:rgb(0,0,0)'*/}
              <rect className="bg-rectangle" />
              <rect className="inner-rectangle" />
              <rect className="extra-rectangle" />
              <circle className="outer-plate-line" />
              <circle className="inner-plate-line" />
              {/* Data*/}
              {/* Current Eth Price*/}
              <text x="35" y="45" font-weight="bold" fill="brown">
                Current Price:
              </text>
              <text x="175" y="45" font-weight="normal" fill="brown">
                ${_latestPrice}{" "}
              </text>
              {/* Strike Price*/}
              <text x="35" y="60" font-weight="bold" fill="brown">
                Strike Price:
              </text>
              <text x="175" y="60" font-weight="normal" fill="brown">
                ${_strikePrice}{" "}
              </text>
              {/* Stable Coin Invested (conversion)*/}
              <text x="35" y="75" font-weight="bold" fill="brown">
                USDC Invested:
              </text>
              <text x="175" y="75" font-weight="normal" fill="brown">
                ${_lendingBalance}{" "}
              </text>
              {/* Energy*/}
              <text x="35" y="90" font-weight="bold" fill="brown">
                Energy:
              </text>
              <text x="175" y="90" font-weight="normal" fill="brown">
                {" "}
                {_energy}
              </text>
              {/* ##### Top Middle*/}
              {/* Token Id*/}
              <text
                x="50%"
                y="23"
                text-anchor="middle"
                font-weight="bold"
                font-size="1.1em"
                fill="white"
              >
                {" "}
                {_tokenId}{" "}
              </text>
              {/* //// Bottom Middle/ */}
              <text
                x="50%"
                y="338"
                text-anchor="middle"
                font-weight="bold"
                font-size="1.1em"
                fill="white"
              >
                {" "}
                ETHEREUM{" "}
              </text>
              {/* Main image*/}
              {/* Error Message*/}
              Unsupported
            </svg>
          </div>

          <div className="button-group">
            <div
              className="btn btn-bordered-white"
              onClick={() => this.mintNFT(this.state.ether, this.state.percent)}
            >
              <i className="icon-rocket mr-2" />
              {this.state.data.btn_1}
            </div>
          </div>
        </div>
        {/* Shape */}
        <div className="shape">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 1440 465"
            version="1.1"
          >
            <defs>
              <linearGradient
                x1="49.7965246%"
                y1="28.2355058%"
                x2="49.7778147%"
                y2="98.4657689%"
                id="linearGradient-1"
              >
                <stop stopColor="rgba(69,40,220, 0.15)" offset="0%" />
                <stop stopColor="rgba(87,4,138, 0.15)" offset="100%" />
              </linearGradient>
            </defs>
            <g
              id="Page-1"
              stroke="none"
              strokeWidth={1}
              fill="none"
              fillRule="evenodd"
            ></g>
          </svg>
        </div>
      </section>
    );
  }
}

export default Mint;
