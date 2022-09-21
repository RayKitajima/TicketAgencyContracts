//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "../src/AgencyFactory.sol";
import "../src/Agency.sol";
import "../src/Show.sol";

import "./CONST.sol";

/**
 * Example setup of "Forge Music Fes. 2022".
 *
 * This music fes. run for two days. (two shows)
 *
 * Seat types are "Standard", "VIP" and "VVIP",
 * its prices are 0.0001, 0.0002 and 0.0003 ether respectively.
 *
 * Capacity of "Standard" is 500, "VIP" is 100 and "VVIP" is 20.
 *
 * usage:
 *   MusicFes fesContract = new MusicFes(address(this));
 *   fesContract.deploy();
 *   fesContract.setAllShowsScheduled();
 *
 */
contract MusicFes {
    Vm vm;
    address owner;

    AgencyFactory public agencyFactoryContract;
    Agency public agencyContract;
    address public agencyAddress;

    uint256 public showDay1Id;
    Show public showDay1;

    uint256 public showDay2Id;
    Show public showDay2;

    mapping(uint256 => FesSeatTypes) public showSeatTypes;

    /**
     * @param _vm VM environment for testing
     * @param _owner The address of the owner of this contract.
     */
    constructor(Vm _vm, address _owner, AgencyFactory _agencyFactoryContract) {
        vm = _vm;
        owner = _owner;
        agencyFactoryContract = _agencyFactoryContract;
    }

    function setup() public {
        setupAgency();
        setupShowDay1();
        setupShowDay2();
    }

    function setupAgency() internal {
        (uint256 agencyId, address _agencyAddress) = agencyFactoryContract.createAgency{
            value: 0.01 ether
        }(
            "Forge Music Fes. 2022 Ticket Agency",
            "The Forge music festival is an annual event that takes place in the city of Los Angeles, California. It is a two-day event that features a variety of different genres of music, including rock, pop, hip hop, and EDM. The festival takes place on the first weekend of November, and it is typically held at the Los Angeles Memorial Coliseum.",
            "https://musicfes2022.example.com/header.png"
        );
        agencyContract = agencyFactoryContract.getAgency(agencyId);
        agencyContract.transferOwnershipTo(owner); // transfer ownership to 'owner' from this (MusicFes) contract

        agencyAddress = _agencyAddress;
    }

    function setupShowDay1() internal {
        vm.startPrank(owner);
        showDay1Id = agencyContract.createShow(
            "Forge Music Fes. 2022 Day1",
            "The first day of Forge music festival is always the most anticipated. This year is no different, as some of the biggest names in the business are set to take the stage. Kicking things off is headliner Saleem Mubin, who is sure to get the crowd hyped up with his high-energy performance. Also on the bill are Burgundy Sadiq, Korneli Grazyna, and many more. With such a stacked lineup, day one is sure to be one for the books.",
            "https://musicfes2022.example.com/day1title.png",
            "2022-11-05",
            "10:00",
            "20:00"
        );
        showDay1 = agencyContract.getShow(showDay1Id);
        showDay1.transferOwnershipTo(owner);
        setupSeats(showDay1);
        vm.stopPrank();
    }

    function setupShowDay2() internal {
        vm.startPrank(owner);
        showDay2Id = agencyContract.createShow(
            "Forge Music Fes. 2022 Day2",
            "The second day of Forge music festival was even more fun and exciting than the first! The lineup of artists was incredible, and the crowd was pumped up and ready to party. The energy was electric and the vibes were good all around. It was truly a magical experience.",
            "https://musicfes2022.example.com/day2title.png",
            "2022-11-06",
            "10:00",
            "20:00"
        );
        showDay2 = agencyContract.getShow(showDay2Id);
        showDay2.transferOwnershipTo(owner);
        setupSeats(showDay2);
        vm.stopPrank();
    }

    function setupSeats(Show show) internal {
        FesSeatTypes seatTypes = new FesSeatTypes(show);

        seatTypes.addSeatType("Standard", 1 * CONST.TICKET_PRICE_UNIT, 500);
        seatTypes.addSeatType("VIP", 2 * CONST.TICKET_PRICE_UNIT, 100);
        seatTypes.addSeatType("VVIP", 3 * CONST.TICKET_PRICE_UNIT, 20);

        showSeatTypes[show.showId()] = seatTypes;
    }

    function deploy() public {
        // deploy seats for showDay1
        FesSeatTypes seatTypesDay1 = showSeatTypes[showDay1.showId()];
        seatTypesDay1.deploy(vm, owner);

        // deploy seats for showDay2
        FesSeatTypes seatTypesDay2 = showSeatTypes[showDay2.showId()];
        seatTypesDay2.deploy(vm, owner);
    }

    function setAllShowsScheduled() public {
        vm.startPrank(owner);
        showDay1.setShowScheduled();
        showDay2.setShowScheduled();
        vm.stopPrank();
    }
}

contract FesSeatTypes {
    Show show;
    string[] seatTypeNames; // Show#addSeatTypes requires dynamic size array
    uint256[] seatTypePrices;
    uint256[] capacities;

    constructor(Show _show) {
        show = _show;
    }

    function addSeatType(
        string memory _name,
        uint256 _price,
        uint256 _capacity
    ) public {
        seatTypeNames.push(_name);
        seatTypePrices.push(_price);
        capacities.push(_capacity);
    }

    function deploy(Vm _vm, address _owner) public {
        _vm.startPrank(_owner);
        uint256[] memory seatTypeIds = show.addSeatTypes(
            seatTypeNames,
            seatTypePrices
        );
        _vm.stopPrank();

        // check seatTypeIds.length == seatTypeNames.length == seatTypePrices.length
        if (seatTypeIds.length != seatTypeNames.length) {
            revert("seatTypeIds.length != seatTypeNames.length");
        }
        if (seatTypeIds.length != seatTypePrices.length) {
            revert("seatTypeIds.length != seatTypePrices.length");
        }
        // make and deploy seats
        for (uint256 i = 0; i < seatTypeIds.length; i++) {
            string memory seatNamePrefix = string(
                abi.encodePacked(seatTypeNames[i], "-")
            ); // (e.g. Standard-1, Standard-2, ...)
            makeSeats(
                _vm,
                _owner,
                seatTypeIds[i],
                seatNamePrefix,
                capacities[i]
            );
        }
    }

    function makeSeats(
        Vm _vm,
        address _owner,
        uint256 seatTypeId,
        string memory prefix,
        uint256 total
    ) public {
        FesSeats seats = new FesSeats(show, seatTypeId);
        for (uint256 i = 0; i < total; i++) {
            // seat name start from 1 (e.g. Standard-1, Standard-2, ...)
            string memory seatName = string(
                abi.encodePacked(prefix, Strings.toString(i + 1))
            );
            seats.addSeat(seatName);
        }
        seats.deploy(_vm, _owner);
    }
}

contract FesSeats {
    Show show;
    uint256 seatTypeId;
    string[] seatNames;

    constructor(Show _show, uint256 _seatTypeId) {
        show = _show;
        seatTypeId = _seatTypeId;
    }

    function addSeat(string memory _name) public {
        seatNames.push(_name);
    }

    function deploy(Vm _vm, address _owner) public {
        _vm.startPrank(_owner);
        uint256[] memory seatNums = show.addSeats(seatTypeId, seatNames);
        _vm.stopPrank();

        // check seatNums == seatNames.length
        if (seatNums.length != seatNames.length) {
            revert("seatNums != seatNames.length");
        }
    }
}
