import React, { Component } from "react";

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};

class Mint extends Component {
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
      <section className="hero-section">
        <div className="container">

        <label for="Coin">ETH to add:</label>
        <input type="number" id="Coin" name="Coin" min="0.1" step="0.01" />
        <label for="DipPercent">Percent Dip to Repurchase:</label>
        <input type="number" id="DipPercent" name="DipPercent" min="10" step="1" max="100" />
          Preview:
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="-25 -25 1440 400"
            version="1.1"
          >
          <rect width="350" height="350" stroke="green" stroke-width="1em"/>
          </svg>

          <div className="button-group">
            <a className="btn btn-bordered-white" href="/explore-1">
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
