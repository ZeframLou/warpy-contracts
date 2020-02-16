// We require the Buidler Runtime Environment explicitly here. This is optional
// when running the script with `buidler run <script>`: you'll find the Buidler
// Runtime Environment's members available as global variable in that case.
const env = require("@nomiclabs/buidler");

async function main() {
  const WarpyRelayer = env.artifacts.require("WarpyRelayer");
  const WCHAI_ADDR = "0x7e7699d76D3b21F870FD2474531CE0D4006Af3ab";

  const relayer = await WarpyRelayer.new(WCHAI_ADDR);
  console.log(`Deployed WarpyRelayer at address ${relayer.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });