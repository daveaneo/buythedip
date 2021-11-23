const initialState = {
  web3Data: {
    address: null,
  },
  isBridgeDown: true,
  amountEntered: 0,
  isFAQOpen: false,
  isGuideOpen: false,
  isSuccessNoticeOpen: false,
  isErrorNoticeOpen: false,
  isFinalSuccessNoticeOpen: false,
  transferAmount: 0,
  isWrongNetworkOpen: false,
  balanceFieldsShouldUpdate: false,
};

// todo - implement immutable check
export const reducer = (prevState = initialState, action) => {
  switch (action.type) {
    case "UPDATE_WEB3":
      return {
        ...prevState,
        web3Data: action.payload,
      };
    case "UPDATE_BALANCEFIELDS":
      return {
        ...prevState,
        balanceFieldsShouldUpdate: action.payload,
      };
    case "UPDATE_ADDRESS":
      return {
        ...prevState,
        web3Data: {
          ...prevState.web3Data,
          address: action.payload,
        },
      };
    case "UPDATE_AMOUNT":
      return {
        ...prevState,
        amountEntered: action.payload,
      };
    case "UPDATE_ISSUCCESSNOTICEOPEN":
      return {
        ...prevState,
        isSuccessNoticeOpen: action.payload,
      };
    case "UPDATE_ISERRORNOTICEOPEN":
      return {
        ...prevState,
        isErrorNoticeOpen: action.payload,
      };
    case "UPDATE_ISGUIDEOPEN":
      return {
        ...prevState,
        isGuideOpen: action.payload,
      };
    case "UPDATE_ISFAQOPEN":
      return {
        ...prevState,
        isFAQOpen: action.payload,
      };
    case "UPDATE_ISWRONGNETWORKOPEN":
      return {
        ...prevState,
        isWrongNetworkOpen: action.payload,
      };
    case "UPDATE_ISFINALSUCCESSNOTICEOPEN":
      return {
        ...prevState,
        isFinalSuccessNoticeOpen: action.payload,
      };
    case "UPDATE_BRIDGE_STATUS":
      return {
        ...prevState,
        isBridgeDown: action.payload,
      };
    case "UPDATE_TRANSFERAMOUNT":
      return {
        ...prevState,
        transferAmount: action.payload,
      };
    default:
      return prevState;
  }
};

export function getState(state) {
  const {
    web3Data,
    isBridgeDown,
    amountEntered,
    isFAQOpen,
    isGuideOpen,
    isSuccessNoticeOpen,
    isErrorNoticeOpen,
    isFinalSuccessNoticeOpen,
    transferAmount,
    isWrongNetworkOpen,
    balanceFieldsShouldUpdate,
  } = state;
  return {
    web3Data,
    isBridgeDown,
    amountEntered,
    isFAQOpen,
    isGuideOpen,
    isSuccessNoticeOpen,
    isErrorNoticeOpen,
    isFinalSuccessNoticeOpen,
    transferAmount,
    isWrongNetworkOpen,
    balanceFieldsShouldUpdate,
  };
}
