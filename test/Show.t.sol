//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Test.sol";
import "openzeppelin/contracts/utils/Strings.sol";

import "../src/AgencyFactory.sol";
import "../src/Agency.sol";
import "../src/Show.sol";

import "./CONST.sol";
import "./MusicFes.sol";

contract ShowTest is Test {
    address owner;

    MusicFes fesContract;
    AgencyFactory agencyFactoryContract;
    Agency agencyContract;

    function setUp() public {
        owner = address(this);
        agencyFactoryContract = new AgencyFactory();

        fesContract = new MusicFes(vm, owner, agencyFactoryContract);
        vm.deal(address(fesContract), 100 ether);
        fesContract.setup();

        agencyContract = fesContract.agencyContract();
        vm.deal(address(agencyContract), 100 ether);

        vm.deal(address(this), 100 ether);

        fesContract.deploy();
    }

    function testAgencyFactory() public {
        AgencyFactory.AgencyDigest[]
            memory agencyDigests = agencyFactoryContract.getAgenciesByAddress(
                owner
            );
        assertEq(agencyDigests.length, 1, "agencyDigests.length should be 1");

        AgencyFactory.AgencyDigest memory agencyDigest = agencyDigests[0];
        assertTrue(
            Utils.strcmp(
                agencyDigest.title,
                "Forge Music Fes. 2022 Ticket Agency"
            ),
            "Agency title is not correct"
        );
        assertEq(
            agencyDigest.agencyAddress,
            address(agencyContract),
            "Agency address is not correct"
        );
    }

    function testAgency() public {
        assertTrue(
            Utils.strcmp(
                agencyContract.title(),
                "Forge Music Fes. 2022 Ticket Agency"
            ),
            "Agency title is not correct"
        );

        assertTrue(
            Utils.strcmp(
                agencyContract.description(),
                "The Forge music festival is an annual event that takes place in the city of Los Angeles, California. It is a two-day event that features a variety of different genres of music, including rock, pop, hip hop, and EDM. The festival takes place on the first weekend of November, and it is typically held at the Los Angeles Memorial Coliseum."
            ),
            "Agency description is not correct"
        );

        assertTrue(
            Utils.strcmp(
                agencyContract.image(),
                "https://musicfes2022.example.com/header.png"
            ),
            "Agency image URL is not correct"
        );

        Agency.ShowDigest[] memory showDigests = agencyContract
            .getShowsDigests();
        assertEq(showDigests.length, 2, "Should have 2 show");
    }

    function testShowDay1() public {
        uint256 showDay1Id = fesContract.showDay1Id();
        Show showDay1 = fesContract.showDay1();

        assertEq(showDay1Id, 0, "Show id should be 0");
        assertTrue(
            showDay1.status() == Show.Status.Pendding,
            "Show status should be Pendding"
        );

        Agency.ShowDigest memory showDigest = agencyContract.getShowDigest(
            showDay1Id
        );

        assertTrue(
            Utils.strcmp(showDigest.title, "Forge Music Fes. 2022 Day1"),
            "Show title is wrong"
        );
        assertTrue(
            Utils.strcmp(
                showDigest.description,
                "The first day of Forge music festival is always the most anticipated. This year is no different, as some of the biggest names in the business are set to take the stage. Kicking things off is headliner Saleem Mubin, who is sure to get the crowd hyped up with his high-energy performance. Also on the bill are Burgundy Sadiq, Korneli Grazyna, and many more. With such a stacked lineup, day one is sure to be one for the books."
            ),
            "Show description is wrong"
        );
        assertTrue(
            Utils.strcmp(
                showDigest.image,
                "https://musicfes2022.example.com/day1title.png"
            ),
            "Show image is wrong"
        );
        assertTrue(
            Utils.strcmp(showDigest.date, "2022-11-05"),
            "Show date is wrong"
        );
        assertTrue(
            Utils.strcmp(showDigest.openingTime, "10:00"),
            "Show opening time is wrong"
        );
        assertTrue(
            Utils.strcmp(showDigest.closingTime, "20:00"),
            "Show closing time is wrong"
        );
    }

    function testUpdateShowDay1() public {
        Show showDay1 = fesContract.showDay1();

        vm.startPrank(owner);

        showDay1.updateTitle("Forge Music Fes. 2022 Day1 (updated)");
        assertTrue(
            Utils.strcmp(
                showDay1.title(),
                "Forge Music Fes. 2022 Day1 (updated)"
            ),
            "Show title is wrong"
        );

        showDay1.updateDescription(
            "The first day of Forge music festival is always the most anticipated. This year is no different, as some of the biggest names in the business are set to take the stage. Kicking things off is headliner Saleem Mubin, who is sure to get the crowd hyped up with his high-energy performance. Also on the bill are Burgundy Sadiq, Korneli Grazyna, and many more. With such a stacked lineup, day one is sure to be one for the books. (updated)"
        );
        assertTrue(
            Utils.strcmp(
                showDay1.description(),
                "The first day of Forge music festival is always the most anticipated. This year is no different, as some of the biggest names in the business are set to take the stage. Kicking things off is headliner Saleem Mubin, who is sure to get the crowd hyped up with his high-energy performance. Also on the bill are Burgundy Sadiq, Korneli Grazyna, and many more. With such a stacked lineup, day one is sure to be one for the books. (updated)"
            ),
            "Show description is wrong"
        );

        showDay1.updateImage(
            "https://musicfes2022.example.com/day1titleUpdated.png"
        );
        assertTrue(
            Utils.strcmp(
                showDay1.image(),
                "https://musicfes2022.example.com/day1titleUpdated.png"
            ),
            "Show image is wrong"
        );

        showDay1.updateDate("2022-11-06");
        assertTrue(
            Utils.strcmp(showDay1.date(), "2022-11-06"),
            "Show date is wrong"
        );

        showDay1.updateOpeningTime("10:30");
        assertTrue(
            Utils.strcmp(showDay1.openingTime(), "10:30"),
            "Show opening time is wrong"
        );

        showDay1.updateClosingTime("20:30");
        assertTrue(
            Utils.strcmp(showDay1.closingTime(), "20:30"),
            "Show closing time is wrong"
        );

        showDay1.setShowScheduled();
        assertTrue(
            showDay1.status() == Show.Status.Scheduled,
            "Show status should be Scheduled"
        );

        vm.stopPrank();
    }

    function testShowDay2() public {
        uint256 showDay2Id = fesContract.showDay2Id();
        Show showDay2 = fesContract.showDay2();

        assertEq(showDay2Id, 1, "Show id should be 1");
        assertTrue(
            showDay2.status() == Show.Status.Pendding,
            "Show status should be Pendding"
        );

        Agency.ShowDigest memory showDigest = agencyContract.getShowDigest(
            showDay2Id
        );

        assertTrue(
            Utils.strcmp(showDigest.title, "Forge Music Fes. 2022 Day2"),
            "Show title is wrong"
        );
        assertTrue(
            Utils.strcmp(
                showDigest.description,
                "The second day of Forge music festival was even more fun and exciting than the first! The lineup of artists was incredible, and the crowd was pumped up and ready to party. The energy was electric and the vibes were good all around. It was truly a magical experience."
            ),
            "Show description is wrong"
        );
        assertTrue(
            Utils.strcmp(
                showDigest.image,
                "https://musicfes2022.example.com/day2title.png"
            ),
            "Show image is wrong"
        );
        assertTrue(
            Utils.strcmp(showDigest.date, "2022-11-06"),
            "Show date is wrong"
        );
        assertTrue(
            Utils.strcmp(showDigest.openingTime, "10:00"),
            "Show opening time is wrong"
        );
        assertTrue(
            Utils.strcmp(showDigest.closingTime, "20:00"),
            "Show closing time is wrong"
        );
    }

    function testUpdateShowDay2() public {
        Show showDay2 = fesContract.showDay2();

        vm.startPrank(owner);

        showDay2.updateTitle("Forge Music Fes. 2022 Day2 (updated)");
        assertTrue(
            Utils.strcmp(
                showDay2.title(),
                "Forge Music Fes. 2022 Day2 (updated)"
            ),
            "Show title is wrong"
        );

        showDay2.updateDescription(
            "The second day of Forge music festival was even more fun and exciting than the first! The lineup of artists was incredible, and the crowd was pumped up and ready to party. The energy was electric and the vibes were good all around. It was truly a magical experience. (updated)"
        );
        assertTrue(
            Utils.strcmp(
                showDay2.description(),
                "The second day of Forge music festival was even more fun and exciting than the first! The lineup of artists was incredible, and the crowd was pumped up and ready to party. The energy was electric and the vibes were good all around. It was truly a magical experience. (updated)"
            ),
            "Show description is wrong"
        );

        showDay2.updateImage(
            "https://musicfes2022.example.com/day2titleUpdated.png"
        );
        assertTrue(
            Utils.strcmp(
                showDay2.image(),
                "https://musicfes2022.example.com/day2titleUpdated.png"
            ),
            "Show image is wrong"
        );

        showDay2.updateDate("2022-11-07");
        assertTrue(
            Utils.strcmp(showDay2.date(), "2022-11-07"),
            "Show date is wrong"
        );

        showDay2.updateOpeningTime("9:30");
        assertTrue(
            Utils.strcmp(showDay2.openingTime(), "9:30"),
            "Show opening time is wrong"
        );

        showDay2.updateClosingTime("19:30");
        assertTrue(
            Utils.strcmp(showDay2.closingTime(), "19:30"),
            "Show closing time is wrong"
        );

        showDay2.setShowScheduled();
        assertTrue(
            showDay2.status() == Show.Status.Scheduled,
            "Show status should be Scheduled"
        );

        vm.stopPrank();
    }

    function testDay1Seat() public {
        Show show = agencyContract.getShow(0);
        subtestSeatTypes(show);
    }

    function testDay2Seat() public {
        Show show = agencyContract.getShow(1);
        subtestSeatTypes(show);
    }

    function subtestSeatTypes(Show show) public {
        // get seat types
        (
            ,
            // uint256[] memory seatTypeIds
            string[] memory seatTypeNames,
            uint256[] memory prices,
            bool[] memory availables
        ) = show.getSeatTypes();

        // test seat type names
        assertTrue(
            Utils.strcmp(seatTypeNames[0], "Standard"),
            "Seat type name is wrong"
        );
        assertTrue(
            Utils.strcmp(seatTypeNames[1], "VIP"),
            "Seat type name is wrong"
        );
        assertTrue(
            Utils.strcmp(seatTypeNames[2], "VVIP"),
            "Seat type name is wrong"
        );

        // test seat type prices
        assertEq(
            prices[0],
            1 * CONST.TICKET_PRICE_UNIT,
            "Seat type price is wrong"
        );
        assertEq(
            prices[1],
            2 * CONST.TICKET_PRICE_UNIT,
            "Seat type price is wrong"
        );
        assertEq(
            prices[2],
            3 * CONST.TICKET_PRICE_UNIT,
            "Seat type price is wrong"
        );

        // test seat type availabilities
        assertTrue(availables[0], "Seat type should be available");
        assertTrue(availables[1], "Seat type should be available");
        assertTrue(availables[2], "Seat type should be available");

        // test "Standard" 500 seats
        subtestSeats(show, 0, "Standard-", 500);
        // test "VIP" 100 seats
        subtestSeats(show, 1, "VIP-", 100);
        // test "VVIP" 50 seats
        subtestSeats(show, 2, "VVIP-", 20);
    }

    function subtestSeats(
        Show show,
        uint256 seatTypeId,
        string memory seatNamePrefix,
        uint256 seatNum
    ) public {
        // test each seat
        string memory seatName;
        for (uint256 i = 0; i < seatNum; i++) {
            // test seat name
            seatName = string(
                abi.encodePacked(seatNamePrefix, Strings.toString(i + 1))
            );
            assertTrue(
                Utils.strcmp(show.getSeatName(seatTypeId, i), seatName),
                "Seat name is wrong"
            );
            // test seat availability
            assertTrue(
                show.isSeatAvailable(seatTypeId, i),
                "Seat should be available"
            );
        }
    }
}
