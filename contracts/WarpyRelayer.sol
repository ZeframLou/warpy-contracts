pragma solidity 0.5.16;

import "@openzeppelin/contracts/GSN/GSNRecipient.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./interfaces/KyberNetwork.sol";
import "./interfaces/Dai.sol";
import "./interfaces/Chai.sol";

contract WarpyRelayer is GSNRecipient, Ownable {
    using SafeMath for uint256;

    // DAI contract constants
    bytes32 internal constant DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;
    bytes32 internal constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    // Contract addresses
    address public constant KYBER_ADDR = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;
    address public constant DAI_ADDR = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant CHAI_ADDR = 0x06AF07097C9Eeb7fD685c692751D5C66dB49c215;
    address internal constant ETH_ADDR = address(
        0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee
    ); // denotes ETH in KyberNetwork
    // Constants
    uint256 public constant FEE = 2 * (10**18); // 2 DAI fee per deposit
    address public constant KYBER_BENEFICIARY = 0x332D87209f7c8296389C307eAe170c2440830A47;
    bytes internal constant PERM_HINT = "PERM";
    uint256 internal constant MAX_QTY = (10**28); // 10B tokens

    /**
        Main
     */

    // Takes DAI from the user, converts it into CHAI, and deposits it into the sidechain bridge contract
    // Also takes a fixed fee to cover the gas cost on the Gas Station Network
    function depositDAI(
        address to,
        uint256 amount,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        // permit DAI to WarpyRelayer using user signature
        Dai dai = Dai(DAI_ADDR);
        dai.permit(to, address(this), dai.nonces(to), expiry, true, v, r, s);

        // transfer DAI from `to` to WarpyRelayer
        dai.transferFrom(to, address(this), amount);

        // take fee from DAI, and convert to ETH using Kyber Network
        uint256 amountAfterFee = amount.sub(FEE); // implicitly ensures amount >= FEE
        KyberNetwork kyber = KyberNetwork(KYBER_ADDR);
        dai.approve(KYBER_ADDR, FEE);
        uint256 feeInETH = kyber.tradeWithHint(
            DAI_ADDR,
            FEE,
            ETH_ADDR,
            address(this),
            MAX_QTY,
            1,
            KYBER_BENEFICIARY,
            PERM_HINT
        );

        // deposit ETH fee into GSNRelayHub for WarpyRelayer
        IRelayHub relayHub = IRelayHub(getHubAddr());
        relayHub.depositFor.value(feeInETH)(address(this));

        // convert DAI to CHAI
        Chai chai = Chai(CHAI_ADDR);
        dai.approve(CHAI_ADDR, amountAfterFee);
        chai.join(address(this), amountAfterFee);

        // lock CHAI to bridge contract
        uint256 chaiAmount = chai.balanceOf(address(this));
    }

    function generateDAIPermitHash(address to, uint256 amount, uint256 expiry)
        public
        view
        returns (bytes32 digest)
    {
        Dai dai = Dai(DAI_ADDR);
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        to,
                        address(this),
                        dai.nonces(to),
                        expiry,
                        true
                    )
                )
            )
        );
    }

    /**
        GSN Inherited
     */

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory) {
        // only accept calls to depositDAI()
        bool shouldAccept = (
            (encodedFunction[0] == this.depositDAI.selector[0]) &&
            (encodedFunction[1] == this.depositDAI.selector[1]) &&
            (encodedFunction[2] == this.depositDAI.selector[2]) &&
            (encodedFunction[3] == this.depositDAI.selector[3]));
        if (shouldAccept) {
            return _approveRelayedCall();
        } else {
            return _rejectRelayedCall(1);
        }
    }

    function _preRelayedCall(bytes memory context) internal returns (bytes32) {}

    function _postRelayedCall(
        bytes memory context,
        bool,
        uint256 actualCharge,
        bytes32
    ) internal {}

    /**
        GSN Admin
     */

    function withdrawETHInRelayer(uint256 amount, address payable payee)
        public
        onlyOwner
    {
        _withdrawDeposits(amount, payee);
    }

    function upgradeRelayHub(address newRelayHub) public onlyOwner {
        _upgradeRelayHub(newRelayHub);
    }

    function() external payable {}
}
