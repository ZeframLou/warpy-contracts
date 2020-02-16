pragma solidity 0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interfaces/Chai.sol";

contract WrappedChai is ERC20, Ownable {
    string  public constant name = "Wrapped Chai";
    string  public constant symbol = "WCHAI";
    uint8   public constant decimals = 18;
    address public constant CHAI_ADDR = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;

    function mintAndApproveOwner(address account, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        // Transfer Chai from owner
        Chai chai = Chai(CHAI_ADDR);
        chai.transferFrom(owner(), address(this), amount);

        // Mint and approve WCHAI
        _mint(account, amount);
        _approve(account, owner(), amount);

        return true;
    }

    function burnIntoCHAI(address account, uint256 amount) external onlyOwner returns (bool) {
        // Burn WCHAI of msg.sender
        _burn(account, amount);

        // Send CHAI to Owner
        Chai chai = Chai(CHAI_ADDR);
        chai.transfer(owner(), amount);

        return true;
    }
}
