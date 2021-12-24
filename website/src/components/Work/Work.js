import React, { Component } from 'react';
//import axios from 'axios';

//const BASE_URL = "https://my-json-server.typicode.com/themeland/netstorm-json/work";


const my_data = {
  "preHeading": "How It Works",
  "heading": "Mint interest-earning NFT limit orders",
  "workData": [
    {
      "id": 1,
      "icon": "icons icon-wallet text-effect",
      "title": "Set up your wallet",
      "text": "Once you’ve set up your wallet of choice, connect it by clicking the the 'Connect Wallet' button in the top right corner."
    },
    {
      "id": 2,
      "icon": "icons icon-grid text-effect",
      "title": "Set mint values",
      "text": "Set the amount of ETH to send and the percent decrease in which you want to rebuy ETH."
    },
    {
      "id": 3,
      "icon": "icons icon-drawer text-effect",
      "title": "Mint your NFT",
      "text": "Click the 'Mint' button and approve the transaction. After minting, the price will be automatically monitored."
    },
    {
      "id": 4,
      "icon": "icons icon-bag text-effect",
      "title": "Stake",
      "text": "After you buy the dip, you can use its energy to share in the profit of all WeBuyTheDip NFTs."
    }
  ]
}


class Work extends Component {
    state = {
        data: {},
        workData: []
    }
    componentDidMount(){
//        axios.get(`${BASE_URL}`)
//            .then(res => {
//                this.setState({
//                    data: res.data,
//                    workData: res.data.workData
//                })
//                // console.log(this.state.data)
//            })
//        .catch(err => console.log(err))
            this.setState({
                data: my_data,
                workData: my_data.workData
            })


    }
    render() {
        return (
            <section id="howitworks" className="work-area">
                <div className="container">
                    <div className="row">
                        <div className="col-12">
                            {/* Intro */}
                            <div className="intro mb-4">
                                <div className="intro-content">
                                    <span>{this.state.data.preHeading}</span>
                                    <h3 className="mt-3 mb-0">{this.state.data.heading}</h3>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div className="row items">
                        {this.state.workData.map((item, idx) => {
                            return (
                                <div key={`wd_${idx}`} className="col-12 col-sm-6 col-lg-3 item">
                                    {/* Single Work */}
                                    <div className="single-work">
                                        <i className={item.icon} />
                                        <h4>{item.title}</h4>
                                        <p>{item.text}</p>
                                    </div>
                                </div>
                            );
                        })}
                    </div>
                </div>
            </section>
        );
    }
}

export default Work;