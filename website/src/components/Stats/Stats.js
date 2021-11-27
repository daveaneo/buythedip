import React, { Component } from "react";

const initData = {
  pre_heading: "Tasty NFTs",
  heading: "Buy The Dip",
  content: "Refried Assets and DeFi Bean Company",
  btn_1: "Mint an NFT",
  btn_2: "Contact Us",
};

class Stats extends Component {
  constructor(props) {
    super(props);
    this.state = {
      data: {},
      ether: 0,
      percent: 0,
    };
  }

  componentDidMount() {
    this.setState({
      data: initData,
    });
  }
  render() {
    return (
      <section className="hero-section">
        <div className="container">

          <ul> Stats
          <li> Total Loans: $213,000 </li>
          <li> NFTs:  199</li>
          <li> Dips Bought:  52</li>
          <li> Address:  {this.props.address}</li>

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
