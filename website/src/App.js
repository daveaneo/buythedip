import React, { Component } from "react";

// importing MyRouts where we located all of our theme
import MyRouts from "./routers/routes";
import Header from "./components/Header/Header.js";
import { updateWeb3Data, updateIsWrongNetworkOpen } from "./actions";
import { connect } from "react-redux";
import { getState } from "./reducer";
import Web3Modal from "web3modal";
import Web3 from "web3";
import inject from "./images/inject.png";
import qr from "./images/qr-code.png";
import WalletConnectProvider from "@walletconnect/web3-provider";

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

  updateToReduxStore() {
    const { dispatch } = this.props;
    dispatch(updateWeb3Data(this.state));
  }
  validateNetwork = (networkId) => {
    if (networkId !== (4 || 1 || 97 || 56)) {
      // throw error dialog
    }
  };

  // componentDidMount() {
  //   if (this.web3Modal.cachedProvider) {
  //     this.onConnect();
  //   }
  //   this.updateToReduxStore();
  // }

  render() {
    if (this.props.balanceFieldsShouldUpdate) {
      // this.updateBalance(this.state.accounts);
      // this.props.dispatch(balanceFieldsShouldUpdate(false));`
    }

    return (
      <div>
        <Header
          walletProps={{ connect: this.onConnect, address: this.state.address }}
        />
        <MyRouts />
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
