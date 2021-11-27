import React, { Component } from "react";

// importing MyRouts where we located all of our theme
import Hero from "./components/Hero/Hero";
import Auctions from "./components/Auctions/AuctionsOne";
import MyNFTs from "./components/MyNFTs/MyNFTs";
import Work from "./components/Work/Work";
import Footer from "./components/Footer/Footer";
import ModalSearch from "./components/Modal/ModalSearch";
import ModalMenu from "./components/Modal/ModalMenu";
import Scrollup from "./components/Scrollup/Scrollup";
import Stats from "./components/Stats/Stats";
import Mint from "./components/Mint/Mint";
import Stake from "./components/Stake/Stake";
import Leaderboard from "./components/Leaderboard/Leaderboard";
import Header from "./components/Header/Header.js";
import { updateWeb3Data, updateIsWrongNetworkOpen } from "./actions";
import { connect } from "react-redux";
import { getState } from "./reducer";
import Web3Modal from "web3modal";
import Web3 from "web3";
import inject from "./images/inject.png";
import qr from "./images/qr-code.png";
import WalletConnectProvider from "@walletconnect/web3-provider";
import abiBTD from "./abi/BuyTheDipNFT.json";



class UnconnectedApp extends Component {
  constructor(props) {
    super(props);
    this.state = {
      isDarkModeEnabled: true,
      chainId: null,
      isConnected: false,
      percentFee: 0,
      web3: null,
      fee: 0,
      isBridgeDown: false,
      contractToken: null,
      contractBridge: null,
      paused: false,
      maxSend: null,
    };

    this.web3Modal = new Web3Modal({
      cacheProvider: true,
      providerOptions: {
        // Example with injected providers
        injected: {
          display: {
            logo: inject,
            name: "Injected",
            description: "Connect with the provider in your Browser",
          },
          package: null,
        },
        // Example with WalletConnect provider
        walletconnect: {
          display: {
            logo: qr,
            name: "Mobile",
            description: "Scan qrcode with your mobile wallet",
          },
          package: WalletConnectProvider,
          options: {
            infuraId:
              "https://rinkeby.infura.io/v3/415d8f8ad8bf4a179cabd397a48d08ce", // required
          },
        },
      },
    });
  }

  initWeb3(provider) {
    const web3 = new Web3(provider);

    web3.eth.extend({
      methods: [
        {
          name: "chainId",
          call: "eth_chainId",
          outputFormatter: web3.utils.hexToNumber,
        },
      ],
    });

    return web3;
  }

  subscribeProvider = async (provider) => {
    if (!provider.on) {
      return;
    }
    provider.on("connect", () => {});
    provider.on("close", () => {});
    provider.on("disconnect", () => {
      this.setState({ address: "" });
    });
  };

  onConnect = async () => {
    const provider = await this.web3Modal.connect();
    await this.subscribeProvider(provider);
    const web3 = this.initWeb3(provider);
    const accounts = await web3.eth.getAccounts();
    const address = accounts[0];
    const networkId = await web3.eth.net.getId();

    if (
      !(
        networkId === 1 ||
        networkId === 4 ||
        networkId === 97 ||
        networkId === 56
      )
    ) {
      this.props.dispatch(updateIsWrongNetworkOpen(true));
    }

    const chainId = await web3.eth.chainId();
    const pegBalance = await web3.eth.getBalance(address);

    await this.setState({
      accounts,
      pegBalance,
      web3,
      provider,
      address,
      chainId,
      networkId,
    });

    this.setState({ isConnected: true });
  };

  validateNetwork = (networkId) => {
    if (networkId !== (4 || 1 || 97 || 56)) {
      // throw error dialog
    }
  };

  componentDidMount() {
    if (this.web3Modal.cachedProvider) {
      this.onConnect();
    }
  }



  render() {

  function doTheThing(){
    let buyTheDipAddress = "0x4E0952fAbC59623c57793D4BE3dDb8fAaA11E27A";
    let web3  = new Web3(web3Modal.connect())
    let contract = new web3.eth.Contract(abiBTD,buyTheDipAddress);
    function mintNFT(ether, percentage) {
    this.contract.methods
      .createCollectible(parseInt(percentage))
      .send({from: this.props.props.account, value: parseInt(ether) })
      .then((balance) => {
        console.log(balance);
      });
  };

  mintNFT(0.1,15);
  };
  doTheThing();


    return (
      <div>
        <Header
          walletProps={{ connect: this.onConnect, address: this.state.address }}
        />
        <Hero />
        <Stats props={{ account: this.state.address }}/>
        <Mint props={{
        account: this.state.address,
        web3Modal: this.state.web3Modal,
         }} />
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

function mapStateToProps(state) {
  const {
    web3Data,
    isBridgeDown,
    amountEntered,
    isFAQOpen,
    isGuideOpen,
    dialog,
    isSuccessNoticeOpen,
    isErrorNoticeOpen,
    isFinalSuccessNoticeOpen,
    isWrongNetworkOpen,
    balanceFieldsShouldUpdate,
  } = getState(state);
  return {
    web3Data,
    isBridgeDown,
    amountEntered,
    isFAQOpen,
    isGuideOpen,
    dialog,
    isSuccessNoticeOpen,
    isErrorNoticeOpen,
    isFinalSuccessNoticeOpen,
    isWrongNetworkOpen,
    balanceFieldsShouldUpdate,
  };
}

const App = connect(mapStateToProps)(UnconnectedApp);

export default App;
