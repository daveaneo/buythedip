import React, { Component } from "react";

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};

class Whitepaper extends Component {
  state = {
    data: {},
  };
  componentDidMount() {
    this.setState({
      data: initData,
    });
  }
  render() {
    return (
      <section className="hero-section" id="whitepaper">
        <div className="container">
            <h1>Whitepaper</h1>

            <div className="whitepaper-container">
                WeBuyTheDip NFT is designed to function like a limit buy order that earns interest. The user purchases the NFT with Ether (or BNB, etc, depending on the blockchain) and their funds are converted to stablecoin (USDC), and lent out to Yearn vaults until their strike price hits. The strike price is established at the time of minting by choosing a percentage, and setting the strike price at a decrease of that percentage for the provided coin. For example, 10 ETH are sent to then smart contract with a percent of 25 and a current price of $4,000. The strike price will be 25% off of $4,000, (75% times $4,000) or $3,000. Depending on the blockchain, either Chainlink Keepers or a centralized bot will monitor the price and initiate the purchase when the price falls to or below the strike price. The smart contract then retrieves the stablecoin from the lending vault and repurchase Ether and sending it to the owner. The smart contract is then eligible for staking, having been given some “energy” for buying the dip. This energy deceases as it is staked.
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

export default Whitepaper;
