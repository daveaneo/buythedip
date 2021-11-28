import React, { Component } from "react";
import Web3 from "web3";
import abiBTD from "../../abi/BuyTheDipNFT.json";
import Contract from "web3-eth-contract";
import { encode, decode } from 'js-base64';
// npm install --save js-base64

const initData = {
  pre_heading: "My NFTs",
  heading: "Ethereum",
  btnText: "View All",
};

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

// getAllNFTsByOwner

let data = [
//  {
//    id: "1",
//    img: "/img/image.png",
//    date: "2021-12-09",
//    title: "Virtual Worlds",
//    seller_thumb: "/img/avatar_1.jpg",
//    seller: "@Richard",
//    price: "1.5 BNB",
//    count: "1 of 1",
//  },
//  {
//    id: "2",
//    img: "/img/image.png",
//    date: "2021-10-05",
//    title: "Collectibles",
//    seller_thumb: "/img/avatar_2.jpg",
//    seller: "@JohnDeo",
//    price: "2.7 BNB",
//    count: "1 of 1",
//  },
//  {
//    id: "3",
//    img: "/img/image.png",
//    date: "2021-09-15",
//    title: "Arts",
//    seller_thumb: "/img/avatar_3.jpg",
//    seller: "@MKHblots",
//    price: "2.3 BNB",
//    count: "1 of 1",
//  },
//  {
//    id: "4",
//    img: "/img/image.png",
//    date: "2021-12-29",
//    title: "Robotic Arts",
//    seller_thumb: "/img/avatar_4.jpg",
//    seller: "@RioArham",
//    price: "1.8 BNB",
//    count: "1 of 1",
//  },
//  {
//    id: "5",
//    img: "/img/image.png",
//    date: "2022-01-24",
//    title: "Design Illusions",
//    seller_thumb: "/img/avatar_5.jpg",
//    seller: "@ArtNox",
//    price: "1.7 BNB",
//    count: "1 of 1",
//  },
//  {
//    id: "6",
//    img: "/img/image.png",
//    date: "2022-03-30",
//    title: "Photography",
//    seller_thumb: "/img/avatar_6.jpg",
//    seller: "@Junaid",
//    price: "3.5 BNB",
//    count: "1 of 1",
//  },
];

var dicNFT = {}

class MyNFTs extends Component {
  constructor(props) {
    super(props);
    this.state = {
        initData: {},
        data: [],
    };
  }
  componentDidMount() {
    this.setState({
      initData: initData,
      data: data,
    });
  }

web3  = new Web3(this.props.props.web3Modal.connect());
contract = new web3.eth.Contract(abiBTD,buyTheDipAddress);

  async getTokenInfo(_id) {
    return this.contract.methods
      .tokenURI(_id)
      .call({from: "0xfAD4322F3493481aE03995F90bEA8283f119Dd17"})
      .then((info) => {
        dicNFT[_id] = info;
      });
  }


  populateData(array){
    data = [];
    this.state.data = [];
    for (var i = 0; i < array.length; i++) {
        let pattern =   {
            id: "1",
            img: "/img/image.png",
            date: "2021-12-09",
            title: "Virtual Worlds",
            seller_thumb: "/img/avatar_1.jpg",
            seller: "@Richard",
            price: "1.5 BNB",
            count: "1 of 1",
        }

        let _id = parseInt(array[i]);
        pattern.title = "#"  + _id;
        this.getTokenInfo(_id); // todo wait for completion
        if (_id in dicNFT ){
            console.log("found", _id);
            let encoded = dicNFT[_id].split("data:application/json;base64,")[1];
            let metadata = JSON.parse(decode(encoded));
            let image = metadata["image"];
            pattern.img = image;
            pattern.id = _id;
            pattern.strikePrice = metadata["attributes"][1]["value"];
//            pattern.id = metadata["attributes"];
            pattern.seller_thumb = image;
            data.push(pattern);
        }
        else{
            console.log("_id not in dictionary", _id, "delaying.")
        }

//        console.log(atob(info.value));
    }
    this.state.data = data;
    console.log(data)
    console.log(this.state.data)
  }

  async getAllNFTsByOwner() {
    this.contract.methods
      .getAllNFTsByOwner("0xfAD4322F3493481aE03995F90bEA8283f119Dd17").call({from: "0xfAD4322F3493481aE03995F90bEA8283f119Dd17"})
      .then(NFTArray => {
        console.log("NFTArray", NFTArray);
        this.populateData(NFTArray);
      });
  }


  render() {
//  this.getAllNFTsByOwner();
this.populateData([0,1]);

    return (
      <section className="live-auctions-area">
        <div className="container">
          <div className="row">
            <div className="col-12">
              {/* Intro */}
              <div className="intro d-flex justify-content-between align-items-end m-0">
                <div className="intro-content">
                  <span>{this.state.initData.pre_heading}</span>
                  <h3 className="mt-3 mb-0">{this.state.initData.heading}</h3>
                </div>
                <div className="intro-btn">
                  <a className="btn content-btn" href="/auctions">
                    {this.state.initData.btnText}
                  </a>
                </div>
              </div>
            </div>
          </div>
          <div className="auctions-slides">
            <div className="swiper-container slider-mid items">
              <div className="swiper-wrapper">
                {/* Single Slide */}
                {this.state.data.map((item, idx) => {
                  return (
                    <div key={`auc_${idx}`} className="swiper-slide item">
                      <div className="card">
                        <div className="image-over">
                          <a href="/item-details">
                            <img
                              className="card-img-top"
                              src={item.img}
                              alt=""
                            />
                          </a>
                        </div>
                        {/* Card Caption */}
                        <div className="card-caption col-12 p-0">
                          {/* Card Body */}
                          <div className="card-body">
                            <div className="countdown-times mb-3">
                              <div
                                className="countdown d-flex justify-content-center"
                                data-date={item.date}
                              />
                            </div>
                            <a href="/item-details">
                              <h5 className="mb-0">{item.title}</h5>
                            </a>
                            <a
                              className="seller d-flex align-items-center my-3"
                              href="/item-details"
                            >
                              <img
                                className="avatar-sm rounded-circle"
                                src={item.seller_thumb}
                                alt=""
                              />
                              <span className="ml-2">{item.seller}</span>
                            </a>
                            <div className="card-bottom d-flex justify-content-between">
                              <span>Taylor Pays: {item.price}</span>
                              <span>{item.count}</span>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
              <div className="swiper-pagination" />
            </div>
          </div>
        </div>
      </section>
    );
  }
}

export default MyNFTs;
