//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../src/Agency.sol";
import "../src/Show.sol";
import "../src/Ticket.sol";

/**
 * @dev Buyer model
 */
contract Buyer is IERC721Receiver {
    Agency agencyContract;
    string buyerName;
    Ticket.TicketInfo ticketInfo;
    uint256 ticketId;

    constructor(Agency _agency, string memory _buyerName) {
        agencyContract = _agency;
        buyerName = _buyerName;
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override returns (bytes4) {
        //ERC721 nftContract = ERC721(msg.sender);
        uint256 tokenId = _tokenId;
        bool tokenAdded = true;

        console2.log(_operator);
        console2.log(_from);
        console2.log(tokenId);
        console2.log(string(_data));
        console2.log(tokenAdded);

        return this.onERC721Received.selector;
    }

    receive() external payable {}

    fallback() external payable {}

    function buyTicket(
        uint256 _showId,
        uint256 _seatTypeId,
        uint256 _seatNum,
        uint256 _price
    ) public {
        Show show = agencyContract.getShow(_showId);
        ticketId = show.buyTicket{value: _price}(
            _seatTypeId,
            _seatNum,
            buyerName
        );
        ticketInfo = show.getTicketInfo(ticketId);
    }

    function getTicketInfo() public view returns (Ticket.TicketInfo memory) {
        Show show = agencyContract.getShow(ticketInfo.showId);
        return show.getTicketInfo(ticketId);
    }

    function offerTicket() public {
        Show show = agencyContract.getShow(ticketInfo.showId);
        show.offerTicket(ticketInfo.ticketId);
    }

    function unofferTicket() public {
        Show show = agencyContract.getShow(ticketInfo.showId);
        show.unofferTicket(ticketInfo.ticketId);
    }

    function buyOfferedTicket(
        uint256 _showId,
        uint256 _ticketId,
        uint256 _price
    ) public {
        Show show = agencyContract.getShow(_showId);
        ticketId = show.buyOfferedTicket{value: _price}(_ticketId, buyerName);
        ticketInfo = show.getTicketInfo(ticketId);
    }

    /// should be reverted. buyer cannot cancel ticket
    function cancelTicket() public {    
        Show show = agencyContract.getShow(ticketInfo.showId);
        show.cancelTicket(ticketInfo.ticketId);
    }

    function hasTicket() public view returns (bool) {
        Show show = agencyContract.getShow(ticketInfo.showId);
        return show.existTicket(ticketInfo.ticketId);
    }

    // just return a pre-defined value
    function makeCheckinCode()
        public
        pure
        returns (
            string memory,
            bytes32,
            bytes memory
        )
    {
        string
            memory checkinCodeMessage = "1,1,1,Standard Seat 1-1,John Doe,0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266,1234";
        bytes32 checkinCodeHash = 0xb223c250c598e30151b75bd1adf869a8a2375a2641b65109f4db2409b0874ebe;
        bytes
            memory checkinCodeSig = hex"16d0e572dced3e997fecb252f0903f1ad18523ab700d97d4934897999d2362c26f0d84f9a1cab6e83dbb365ea94392ed729f09a698df53bc391dabd198d281261b";

        return (checkinCodeMessage, checkinCodeHash, checkinCodeSig);
    }
}
