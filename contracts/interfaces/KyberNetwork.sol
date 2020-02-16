pragma solidity 0.5.16;

interface KyberNetwork {
  function getExpectedRate(address src, address dest, uint srcQty) external view
      returns (uint expectedRate, uint slippageRate);

  function tradeWithHint(
    address src, uint srcAmount, address dest, address payable destAddress, uint maxDestAmount,
    uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
}