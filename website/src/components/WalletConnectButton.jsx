import React from "react";
import { connect } from "react-redux";
import { getState } from "../reducer";

const WalletButton = ({ address, onClick }) => {
  // should show even if already connected on page load
  let getTruncatedAddress = () =>
    address.slice(0, 5) +
    "..." +
    address.slice(address.length - 3, address.length); //e9
  let displayText = address
    ? getTruncatedAddress() + " Connected"
    : "Connect Wallet";

  return (
    <div onClick={onClick} className="btn ml-lg-auto btn-bordered-white">
      <p className="buttonText">
        <i className="icon-wallet mr-md-2" />
        {displayText}
      </p>
    </div>
  );
};

function mapStateToProps(state) {
  const { web3Data, isBridgeDown, amountEntered, isWalletConnectOpen } =
    getState(state);
  return {
    web3Data,
    isBridgeDown,
    amountEntered,
    isWalletConnectOpen,
  };
}

const WalletConnectButton = connect(mapStateToProps)(WalletButton);

export default WalletConnectButton;
