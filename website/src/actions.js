export const updateIsWalletConnectOpen = (boolean) => ({
  type: "UPDATE_ISWALLETOPEN",
  payload: boolean,
});
export const updateDialog = (dialog) => ({
  type: "UPDATE_DIALOG",
  payload: dialog,
});
export const updateIsDialogClosed = (boolean) => ({
  type: "UPDATE_IS_DIALOG_CLOSED",
  payload: boolean,
});
export const updateWeb3Data = (data) => ({
  type: "UPDATE_WEB3",
  payload: data,
});
export const updateAmount = (data) => ({
  type: "UPDATE_AMOUNT",
  payload: data,
});
export const updateIsSuccessNoticeOpen = (boolean) => ({
  type: "UPDATE_ISSUCCESSNOTICEOPEN",
  payload: boolean,
});
export const updateIsErrorNoticeOpen = (boolean) => ({
  type: "UPDATE_ISERRORNOTICEOPEN",
  payload: boolean,
});
export const updateIsWrongNetworkOpen = (boolean) => ({
  type: "UPDATE_ISWRONGNETWORKOPEN",
  payload: boolean,
});
export const updateIsFinalSuccessNoticeOpen = (boolean) => ({
  type: "UPDATE_ISFINALSUCCESSNOTICEOPEN",
  payload: boolean,
});
export const balanceFieldsShouldUpdate = (boolean) => ({
  type: "UPDATE_BALANCEFIELDS",
  payload: boolean,
});
export const updateTransferAmount = (amount) => ({
  type: "UPDATE_TRANSFERAMOUNT",
  payload: amount,
});
export const updateIsFAQOpen = (boolean) => ({
  type: "UPDATE_ISFAQOPEN",
  payload: boolean,
});
export const updateIsGuideOpen = (boolean) => ({
  type: "UPDATE_ISGUIDEOPEN",
  payload: boolean,
});
export const updateAddress = (address) => ({
  type: "UPDATE_ADDRESS",
  payload: address,
});
