import React, { Component } from "react";
import Web3 from "web3";
import abiBTD from "../../abi/BuyTheDipNFT.json";
import Contract from "web3-eth-contract";

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};


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

//todo-- create getMinABI function or use existing function to get ABI

Contract.setProvider(ENDPOINT_WSS_ETH_TESTNET);



class Stats extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
      ether: 0,
      percent: 0,
      tokens:0,
      totalLoans:0,
    };
  }

  componentDidMount() {
    this.setState({
      data: initData,
    });
    this.getTokenCounter()
    this.getTotalStableCoin()
  }

  contract = new Contract(abiBTD, buyTheDipAddress);


  getTokenCounter() {
    return this.contract.methods
      .tokenCounter()
      .call()
      .then((tokens) => {
        this.setState({
          tokens: parseInt(tokens),
        });
      });
  }

  numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }

  getTotalStableCoin() {
    return this.contract.methods
      .totalStableCoin()
      .call()
      .then((loans) => {
        this.setState({
          totalLoans: parseFloat(loans/10**6).toFixed(2),
        });
      });
  }


  render() {
    return (
      <section className="hero-section">
        <div className="container">
          <ul> <h1>Stats</h1>
          <li> Total Loans: ${this.numberWithCommas(this.state.totalLoans)} </li>
          <li> Total NFTs:  {this.state.tokens}</li>
          <li> BTD Contract Address:  {buyTheDipAddress}</li>
          <li> Staking Address:  {dipStakingAddress}</li>
          </ul>

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

export default Stats;
