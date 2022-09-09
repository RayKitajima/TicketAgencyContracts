//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "../src/Agency.sol";
import "../src/Show.sol";

import "./MusicFes.sol";
import "./Buyer.sol";

contract BuyingTicketTest is Test, IERC721Receiver {
    address owner;

    MusicFes fesContract;
    Agency agencyContract;

    function setUp() public {
        owner = address(this);
        fesContract = new MusicFes(vm, owner);
        agencyContract = fesContract.agencyContract();
        
        fesContract.deploy();

        vm.deal(address(agencyContract), 100 ether);
        vm.deal(address(fesContract), 100 ether);
        vm.deal(address(this), 100 ether);

        fesContract.setAllShowsScheduled();
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

    function testBuyTicketBasic(
        uint256 _showId,
        uint256 _seatTypeId,
        uint256 _seatNum
    ) public {
        vm.assume(_showId < agencyContract.getShowCount());
        vm.assume(
            _seatTypeId < agencyContract.getShow(_showId).getSeatTypesCount()
        );
        vm.assume(
            _seatNum <
                agencyContract.getShow(_showId).getRawSeats(_seatTypeId).length
        );

        uint256 showId = _showId;
        uint256 seatTypeId = _seatTypeId;
        uint256 seatNum = _seatNum;

        Show show = agencyContract.getShow(showId);
        uint256 seatTypePrice = show.getSeatType(seatTypeId).price;

        // start buyer usecase
        address buyer = address(this);
        vm.startPrank(buyer);

        uint256 ticketId = show.buyTicket{value: seatTypePrice}(
            seatTypeId,
            seatNum,
            "John Doe"
        );

        assertFalse(ticketId == 0, "Ticket id should not be 0");

        assertEq(
            show.getTicketInfo(ticketId).seatTypeId,
            seatTypeId,
            "Ticket seat type id should be seatTypeId1"
        );
        assertEq(
            show.getTicketInfo(ticketId).seatNum,
            seatNum,
            "Ticket seat num should be seatNum1"
        );
        assertEq(
            show.getTicketInfo(ticketId).buyer,
            buyer,
            "Ticket buyer should be buyer"
        );
        assertEq(
            show.getTicketInfo(ticketId).date,
            show.date(),
            "Ticket date should be show date"
        );
        assertEq(
            show.getTicketInfo(ticketId).openingTime,
            show.openingTime(),
            "Ticket time should be show time"
        );
        assertEq(
            show.getTicketInfo(ticketId).closingTime,
            show.closingTime(),
            "Ticket time should be show time"
        );
        assertEq(
            show.getTicketInfo(ticketId).buyerName,
            "John Doe",
            "Ticket name should be John Doe"
        );

        // end buyer usecase
        vm.stopPrank();
    }
}
