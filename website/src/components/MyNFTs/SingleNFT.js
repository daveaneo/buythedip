import Web3 from "web3";
import React, { useEffect, useState } from "react";
import abiBTD from "../../abi/BuyTheDipNFT.json";
import Contract from "web3-eth-contract";


let ENDPOINT_WSS_ETH_TESTNET =
  "wss://speedy-nodes-nyc.moralis.io/fdb0fa9dd36e9d32bea0738f/eth/rinkeby/ws";
Contract.setProvider(ENDPOINT_WSS_ETH_TESTNET);
let web3 = new Web3();
const buyTheDipAddress = "0x5cf87D677FC068be8E0329825C44168A6c51a3F1";
const dipStakingAddress = "0x705A18c726c53114f9A0FDACe1D53CFf85725002";


export const SingleNFT = ({ data, props }) => {

    web3 = new Web3(props.web3Modal.connect());
    web3.setProvider(window.ethereum);
    const contract = new web3.eth.Contract(abiBTD, buyTheDipAddress);

  const stakeNFT = async (_id) => {
      // Approve
    contract.methods
      .approve(dipStakingAddress, _id)
      .send({from: props.account})
      .then((result) => {
        console.log("result of approve: ", result);
      });

      // Transfer
    contract.methods
      .safeTransferFrom(props.account, dipStakingAddress, _id)
      .send({from: props.account})
      .then((result) => {
        console.log("result of safeTransfer: ", result);
      });
    console.log("Done staking.");
 }


  return (
    <div style={{ display: "flex", flexDirection: "row"}}>
      {data.map((item, idx) => {
        return (
          <div key={`auc_${idx}`} className="swiper-slide item" style={{ maxWidth: 350 }}>
            <div className="card">
              <div className="image-over">
                <img className="card-img-top" src={item.img} alt="" />
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
                    <span>{item.asset} on {item.blockchain}</span>
                    <span>{item.count}</span>
                  </div>
                </div>
              </div>
              {item.energy > 0 &&
                <div onClick={() => stakeNFT(item.id)} className="btn btn-bordered-white mt-1">
                  <i className="icon-note mr-2" />
                    STAKE
                </div>
              }
            </div>
          </div>
        );
      })}
    </div>
  );
};
