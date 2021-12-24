import React, { Component } from 'react';
import axios from 'axios';

//const BASE_URL = "https://my-json-server.typicode.com/themeland/netstorm-json-2/footer";

const my_data = {
  "img": "/img/bsllc_logo.png",
  "content": "Providing fair and decentralized services.",
  "widget_1": "Useful Links",
  "widget_2": "Community",
  "widget_3": "Subscribe",
  "socialData": [
    {
      "id": 1,
      "link": "https://t.me/dipnft",
      "icon": "fab fa-telegram"
    },
    {
      "id": 2,
      "link": "https://github.com/daveaneo/buythedip",
      "icon": "fab fa-github"
    },
  ],
  "widgetData_1": [
    {
      "id": 1,
      "text": "Mint",
      "link": "#mint"
    },
    {
      "id": 2,
      "text": "My NFTs",
      "link": "#mynfts"
    },
    {
      "id": 3,
      "text": "My Staked NFTs",
      "link": "#mystakednfts"
    },
    {
      "id": 4,
      "text": "Leaderboard",
      "link": "#leaderboard"
    },
    {
      "id": 5,
      "text": "Whitepaper",
      "link": "#whitepaper"
    },
    {
      "id": 6,
      "text": "How It Works",
      "link": "#howitworks"
    }
  ],
  "widgetData_2": [
    {
      "id": 1,
      "text": "Coming Soon",
      "link": ""
    }
  ]
}

class Footer extends Component {
    state = {
        data: {},
        socialData: [],
        widgetData_1: [],
        widgetData_2: []
    }
    componentDidMount(){
        this.setState({
            data: my_data,
            socialData: my_data.socialData,
            widgetData_1: my_data.widgetData_1,
            widgetData_2: my_data.widgetData_2
        })
    }
    render() {
        return (
            <footer className="footer-area">
                {/* Footer Top */}
                <div className="footer-top">
                    <div className="container">
                        <div className="row">
                            <div className="col-12 col-sm-6 col-lg-3 res-margin">
                                {/* Footer Items */}
                                <div className="footer-items">
                                    {/* Logo */}
                                    <a className="navbar-brand" href="/">
                                        <img src={this.state.data.img} alt="" />
                                    </a>
                                    <p>{this.state.data.content}</p>
                                    {/* Social Icons */}
                                    <div className="social-icons d-flex">
                                        {this.state.socialData.map((item, idx) => {
                                            return (
                                                <a key={`sd_${idx}`} className="" href={item.link}>
                                                    <i className={item.icon} />
                                                    <i className={item.icon} />
                                                </a>
                                            );
                                        })}
                                    </div>
                                </div>
                            </div>
                            <div className="col-12 col-sm-6 col-lg-3 res-margin">
                                {/* Footer Items */}
                                <div className="footer-items">
                                    {/* Footer Title */}
                                    <h4 className="footer-title">{this.state.data.widget_1}</h4>
                                    <ul>
                                        {this.state.widgetData_1.map((item, idx) => {
                                            return (
                                                <li key={`wdo_${idx}`}><a href={item.link}>{item.text}</a></li>
                                            );
                                        })}
                                    </ul>
                                </div>
                            </div>
                            <div className="col-12 col-sm-6 col-lg-3 res-margin">
                                {/* Footer Items */}
                                <div className="footer-items">
                                    {/* Footer Title */}
                                    <h4 className="footer-title">{this.state.data.widget_2}</h4>
                                    <ul>
                                        {this.state.widgetData_2.map((item, idx) => {
                                            return (
                                                <li key={`wdo_${idx}`}><a href={item.link}>{item.text}</a></li>
                                            );
                                        })}
                                    </ul>
                                </div>
                            </div>
                            <div className="col-12 col-sm-6 col-lg-3">
                                {/* Footer Items */}
                                <div className="footer-items">
                                    {/* Footer Title */}
                                    <h4 className="footer-title">{this.state.data.widget_3}</h4>
                                    {/* Subscribe Form */}
                                    <div className="subscribe-form d-flex align-items-center">
                                        <input type="email" className="form-control" placeholder="info@yourmail.com" />
                                        <button type="submit" className="btn"><i className="icon-paper-plane" /></button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
                {/* Footer Bottom */}
                <div className="footer-bottom">
                    <div className="container">
                        <div className="row">
                            <div className="col-12">
                                {/* Copyright Area */}
                                <div className="copyright-area d-flex flex-wrap justify-content-center justify-content-sm-between text-center py-4">
                                    {/* Copyright Left */}
                                    <div className="copyright-left"></div>
                                    <div className="copyright-right">©2021 BlockChain Solutions LLC,  All Rights Reserved.</div>
                                    {/* Copyright Right */}
                                    {/* <div className="copyright-right"> Made With <i className="fas fa-heart" /> <a href="#"> </a></div> */}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </footer>
        );
    }
}

export default Footer;