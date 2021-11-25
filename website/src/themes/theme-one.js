import React, { Component } from "react";

import Header from "../components/Header/Header";
import Hero from "../components/Hero/Hero";
import Auctions from "../components/Auctions/AuctionsOne";
import MyNFTs from "../components/MyNFTs/MyNFTs";
import Work from "../components/Work/Work";
import Footer from "../components/Footer/Footer";
import ModalSearch from "../components/Modal/ModalSearch";
import ModalMenu from "../components/Modal/ModalMenu";
import Scrollup from "../components/Scrollup/Scrollup";
import Stats from "../components/Stats/Stats";
import Mint from "../components/Mint/Mint";
import Stake from "../components/Stake/Stake";
import Leaderboard from "../components/Leaderboard/Leaderboard";

class ThemeOne extends Component {
  render() {
    return (
      <div className="main">
        <Hero />
        <Stats />
        <Mint />
        <MyNFTs />
        <Stake />
        <Leaderboard />
        <Auctions />
        <Work />
        <Footer />
        <ModalSearch />
        <ModalMenu />
        <Scrollup />
      </div>
    );
  }
}

export default ThemeOne;
