import React, { Component } from "react";
import "./Stake.css";
import Web3 from "web3";
//import fs from "fs";
import abiBTD from "../../abi/BuyTheDipNFT.json";
import Contract from "web3-eth-contract";
//const { ethers } = require('ethers');

//const contractJson = fs.readFileSync("../../abi/BuyTheDipNFT.json");

// todo -- change how this page works. Show [ SVG ] (small). Can do this on MyNFTs. Small stake button for eligible.

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};

let _tokenId = 1;
let _dipLevel = 1; //tokenIdToDipLevel[_tokenId];
let _energy = 0;

const buyTheDipAddress = "0x00aC63F453e1bAE95eeFDa74937b2063FD71615C";
const dipStakingAddress = "0x9a03097B1F966aF8a5964D58e23f1a636d306015";
//let ENDPOINT_ETH = "https://rinkeby.infura.io/v3/415d8f8ad8bf4a179cabd397a48d08ce";
//let ENDPOINT_ETH="https://rinkeby.infura.io/v3/415d8f8ad8bf4a179cabd397a48d08ce";
//let ENDPOINT_MAINNET_ETH="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/rinkeby";
//let ENDPOINT_TESTNET_ROPSTEN_ETH="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/ropsten";
//let ENDPOINT_TESTNET_BSC="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/bsc/testnet";
//let ENDPOINT_MAINNET_BSC="https://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/bsc/mainnet";
let ENDPOINT_WSS_ETH_TESTNET="wss://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/rinkeby/ws";
//let ENDPOINT_WSS_BSC_TESTNET="wss://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/bsc/testnet/ws";

Contract.setProvider(ENDPOINT_WSS_ETH_TESTNET);
var web3 = new Web3();
web3.setProvider(window.ethereum);

class Stake extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
      ether: 0.1,
      percent: 25,
      etherPrice: 0,
      tokenCounter:10**14,
    };
  }

 componentDidMount(){
    this.getLatestPrice();
    this.getTokenCounter();
  }

web3  = new Web3(this.props.props.web3Modal.connect());
contract = new web3.eth.Contract(abiBTD,buyTheDipAddress);

  stakeNFT(_id) {
      console.log("NOW STAKING:", _id);

      // Approve
//    btd.approve(dip_staking.address, 0, {"from": dev})
    this.contract.methods
      .approve(dipStakingAddress, _id)
      .send({from: this.props.props.account})
      .then((result) => {
        console.log(result);
      });

      // Transfer
//    btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})
    this.contract.methods
      .safeTransferFrom(this.props.props.account, dipStakingAddress, _id)
      .send({from: this.props.props.account})
      .then((result) => {
        console.log(result);
      });

//    this.contract.methods
//      .createCollectible(parseFloat(percentage))
//      .send({from: this.props.props.account, value: parseFloat(ether)*10**18 })
//      .then((balance) => {
//        console.log(balance);
//      });
  }

  getTokenCounter() {
    return this.contract.methods
      .tokenCounter()
      .call()
      .then((counter) => {
        console.log(counter);
        this.setState({
          tokenCounter: counter,
        });

      });
  }

  getLatestPrice() {
    return this.contract.methods
      .getLatestPrice()
      .call()
      .then((price) => {
        this.setState({
          etherPrice: price,
        });
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
      <section className="hero-section" id="stake">
        <div className="container">
          <h1>Stake</h1>
          <div classname="flex-row">
              <input
                onChange={(event) => this.setState({ NFTToMint: event.target.value })}
                type="number"
                id="TokenId"
                name="TokenId"
                min="0"
                step="1"
                max={this.state.tokenCounter}
                className ="input-field"
                placeholder = "0"
              />
              <label className="input-field-label" for="TokenId">Token Id</label>
           </div>
          <div className="button-group">
            <div
              className="btn btn-bordered-white"
              onClick={() => this.stakeNFT(this.state.NFTToMint)}
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

export default Stake;
