//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Agency.sol";

contract AgencyFactory {
    address public owner;
    uint256 public CREATE_FEE = 0.01 ether; // 0.01 ether
    uint256 public MAX_AGENCY_COUNT = 1000; // max number of agencies stored in the latestAgencies array

    struct AgencyDigest {
        string title; // title of the agency
        address agencyAddress; // address of the agency
    }

    Agency[] public agencies; // list of agencies, agencyId is the index in this array
    AgencyDigest[] public agencyDigests; // list of latest agency digests, agencyId is the index in this array

    function createAgency(
        string memory _title,
        string memory _description,
        string memory _image
    ) public payable returns (uint256, address) {
        require(msg.value >= CREATE_FEE, "Not enough ether sent");

        Agency agency = new Agency(_title, _description, _image);
        agencies.push(agency);
        agency.transferOwnershipTo(msg.sender);

        uint256 agencyId = agencyDigests.length;
        agencyDigests.push(AgencyDigest(_title, address(agency)));

        if (agencyDigests.length > MAX_AGENCY_COUNT) {
            delete agencyDigests[0];
        }

        if (msg.value > CREATE_FEE) {
            uint256 returnValue = msg.value - CREATE_FEE;
            (bool sent, ) = payable(msg.sender).call{value: returnValue}("");
            require(sent, "Failed to send Ether");
        }

        return (agencyId, address(agency));
    }

    function getAgenciesByAddress(address _address)
        public
        view
        returns (AgencyDigest[] memory)
    {
        AgencyDigest[] memory selectedAgencies = new AgencyDigest[](
            agencyDigests.length
        );
        uint256 count = 0;
        for (uint256 i = 0; i < agencyDigests.length; i++) {
            if (agencyDigests[i].agencyAddress == _address) {
                selectedAgencies[count] = agencyDigests[i];
                count++;
            }
        }

        AgencyDigest[] memory result = new AgencyDigest[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = selectedAgencies[i];
        }

        return result;
    }

    function getAgencyDigestsa() public view returns (AgencyDigest[] memory) {
        return agencyDigests;
    }

    // get agency
    function getAgency(uint256 _agencyId) public view returns (Agency) {
        return agencies[_agencyId];
    }

    receive() external payable {}

    fallback() external payable {}
}
