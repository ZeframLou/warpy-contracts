pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LoomWCHAI is ERC20 {
    // Transfer Gateway contract address
    address public gateway;

    string  public constant name = "Wrapped Chai";
    string  public constant symbol = "WCHAI";
    uint8   public constant decimals = 18;

    constructor(address _gateway) public {
        gateway = _gateway;
    }

    // Used by the DAppChain Gateway to mint tokens that have been deposited to the Ethereum Gateway
    function mintToGateway(uint256 _amount) public {
        require(msg.sender == gateway, "only the gateway is allowed to mint");
        _mint(gateway, _amount);
    }
}