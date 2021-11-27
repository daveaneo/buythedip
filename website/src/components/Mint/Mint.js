import React, { Component } from "react";
import "./Mint.css";
import Web3 from "web3";

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
let account = "0xsdfs9lsls..."
let buyTheDipAddress = "0xslisdf..."

//todo-- create getMinABI function or use existing function to get ABI
//let contract = new Web3.eth.Contract(this.getMinABI(), buyTheDipAddress, {
//     from: account
//});

let contract=0;

function mintNFT(Ether, percentage) {
    contract.methods.mint('your address').send(percentage, {from: account, value:Ether}).then((balance) => {
       console.log(balance)
    });


  return true;
}


class Mint extends Component {
  state = {
    data: {},
  };

  render() {

    return (
      <section className="hero-section" id="mint">
        <div className="container">
        <label for="CoinAmount">ETH to add:</label>
        <input type="number" id="CoinAmount" name="CoinAmount" min="0.1" step="0.01" />
        <label for="DipPercent">Percent Dip to Repurchase:</label>
        <input type="number" id="DipPercent" name="DipPercent" min="10" step="1" max="100" />

            { /* PREVIEW OF NFT */}
            <div className="NFT-image-container">
                <svg xmlns='http://www.w3.org/2000/svg' width='350' height='350'>
                    <rect width='350' height='350' className="NFT-box" /> {/* style='fill:rgb(255,255,255);stroke-width:3;stroke:rgb(0,0,0)'*/}
                    <rect className="bg-rectangle"/>
                    <rect className="inner-rectangle"/>
                    <rect className="extra-rectangle"/>
                    <circle className="outer-plate-line"/>
                    <circle className="inner-plate-line"/>

                    {/* Data*/}
                    {/* Current Eth Price*/}
                    <text x='35' y='45' font-weight='bold' fill='brown'>Current Price:</text>
                    <text x='175' y='45' font-weight='normal' fill='brown'>${_latestPrice} </text>
                    {/* Strike Price*/}
                    <text x='35' y='60'  font-weight='bold' fill='brown'>Strike Price:</text>
                    <text x='175' y='60' font-weight='normal' fill='brown'>${_strikePrice} </text>
                    {/* Stable Coin Invested (conversion)*/}
                    <text x='35' y='75'  font-weight='bold' fill='brown'>USDC Invested:</text>
                    <text x='175' y='75' font-weight='normal' fill='brown'>${_lendingBalance} </text>

                    {/* Energy*/}
                    <text x='35' y='90' font-weight='bold' fill='brown'>Energy:</text>
                    <text x='175' y='90' font-weight='normal' fill='brown'> {_energy}</text>
                    {/* ##### Top Middle*/}
                    {/* Token Id*/}
                    <text x='50%' y='23' text-anchor='middle' font-weight='bold' font-size='1.1em' fill='white'> {_tokenId} </text>
                    {/* //// Bottom Middle/ */}
                    <text x='50%' y='338' text-anchor='middle' font-weight='bold' font-size='1.1em' fill='white'> ETHEREUM </text>
                    {/* Main image*/}
                    {/* Error Message*/}
                    Unsupported
                </svg>
            </div>


          <div className="button-group">
            <a className="btn btn-bordered-white">
              <i className="icon-rocket mr-2" />
              {this.state.data.btn_1}
            </a>
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
            >

            </g>
          </svg>
        </div>
      </section>
    );
  }
}

export default Mint;
