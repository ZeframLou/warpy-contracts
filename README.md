# Warpy Smart Contracts

**Warpy is Venmo + them 🔥 DeFi interests**

Warpy smoothly onboards users into a DeFi savings account: sign up with email/phone number & deposit with debit card (Fortmatic), and get interest-bearing DAI (Chai), all without using Ether/gas.

At the same time, Warpy onboards the user and their Chai onto Loom Network, allowing them to send money instantly & for free.

Though Warpy uses Loom Network, it can work with any side chain or roll-up chain that has an asset bridge with Ethereum Mainnet.

## Documentation

`contracts/WarpyRelayer.sol` is the main smart contract.

### `function depositDAI(address to, uint256 amount, uint256 expiry, uint8 v, bytes32 r, bytes32 s) public`
Transfers DAI from the user using a signature, converts it into Chai, and deposits the Chai into the Loom Network Transfer Gateway contract, which will make the Chai available on the Loom Network.

Also takes a fixed fee (2 DAI), which is converted into ETH via Kyber Network, to cover the gas cost on the Gas Station Network.

Should be called by a GSN Relayer, but not necessarily.

### `function withdrawDAI(uint256 amount) public`
Converts the user's Chai into Dai.

Should be called by a GSN Relayer, but not necessarily.
