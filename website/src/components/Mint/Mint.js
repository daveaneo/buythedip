import React, { Component } from "react";
import "./Mint.css";
import Web3 from "web3";
//import fs from "fs";
import abiBTD from "../../abi/BuyTheDipNFT.json";
import Contract from "web3-eth-contract";
//const { ethers } = require('ethers');

//const contractJson = fs.readFileSync("../../abi/BuyTheDipNFT.json");

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};

let _tokenId = 1;
let _dipLevel = 1; //tokenIdToDipLevel[_tokenId];
let _strikePrice = 2500; //uint256(tokenIdToDipValue[_tokenId]);
let _RADIUS = 78; // 80 - 2
let _latestPrice = 4700; //let(getLatestPrice());
let _circleRadius = 0;
let _lendingBalance = 1234;
let _energy = 0;

//const buyTheDipAddress = "0x4E0952fAbC59623c57793D4BE3dDb8fAaA11E27A";
const buyTheDipAddress = "0x538D826935251739E47409990b31c339d1D49749";
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


Contract.setProvider(ENDPOINT_WSS_ETH_TESTNET);
var web3 = new Web3();
web3.setProvider(window.ethereum);

class Mint extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
      ether: 0.1,
      percent: 25,
      etherPrice: 0,
    };
    this.getLatestPrice();
    console.log("STATE: ", this.state);
  }

web3  = new Web3(this.props.props.web3Modal.connect());
contract = new web3.eth.Contract(abiBTD,buyTheDipAddress);

  mintNFT(ether, percentage) {
    this.contract.methods
      .createCollectible(parseFloat(percentage))
      .send({from: this.props.props.account, value: parseFloat(ether)*10**18 })
      .then((balance) => {
        console.log(balance);
      });
  }

  getTokenCounter() {
    return this.contract.methods
      .tokenCounter()
      .call()
      .then((balance) => {
        console.log(balance);
      });
  }

  getLatestPrice() {
    return this.contract.methods
      .getLatestPrice()
      .call()
      .then((price) => {
        console.log("eth price:", price);
        this.state.etherPrice = price;
      });
  }



  getTotalStableCoin() {
    return this.contract.methods
      .totalStableCoin()
      .call()
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
              <text x="35" y="45" fontWeight="bold" fill="brown">
                Current Price:
              </text>
              <text x="175" y="45" fontWeight="normal" fill="brown">
                ${parseFloat(this.state.etherPrice/10**9).toFixed(2)}{" "}
              </text>
              {/* Strike Price*/}
              <text x="35" y="60" fontWeight="bold" fill="brown">
                Strike Price:
              </text>
              <text x="175" y="60" fontWeight="normal" fill="brown">
                ${parseFloat(this.state.percent*this.state.etherPrice/10**9/100).toFixed(2)}{" "}
              </text>
              {/* Stable Coin Invested (conversion)*/}
              <text x="35" y="75" fontWeight="bold" fill="brown">
                USDC Invested:
              </text>
              <text x="175" y="75" fontWeight="normal" fill="brown">
                ${parseFloat(this.state.ether*this.state.etherPrice/10**9).toFixed(2)}{" "}
              </text>
              {/* Energy*/}
              <text x="35" y="90" fontWeight="bold" fill="brown">
                Energy:
              </text>
              <text x="175" y="90" fontWeight="normal" fill="brown">
                {" "}
                {_energy}
              </text>
              {/* ##### Top Middle*/}
              {/* Token Id*/}
              <text
                x="50%"
                y="23"
                textAnchor="middle"
                fontWeight="bold"
                fontSize="1.1em"
                fill="white"
              >
                {" "}
                {_tokenId}{" "}
              </text>
              {/* //// Bottom Middle/ */}
              <text
                x="50%"
                y="338"
                textAnchor="middle"
                fontWeight="bold"
                fontSize="1.1em"
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
