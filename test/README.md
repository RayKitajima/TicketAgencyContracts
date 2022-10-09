
# Test for TicketAgencyContracts

## Test case 

Example agency setup for testing is in [`MusicFes.sol`](MusicFes.sol). 
It is a simple agency that sells tickets for a "Forge Music Fes. 2022" with 2 days. 

Seat types are "Standard", "VIP" and "VVIP", its prices are 0.0001, 0.0002 and 0.0003 ether respectively. 

Capacity of "Standard" is 500, "VIP" is 100 and "VVIP" is 20.

## Tests

| Contract | description |
|:--- |:--- |
| [Show.t.sol](Show.t.sol) | Basic test for Show.sol |
| [TicketContract.t.sol](TicketContract.t.sol) | Basic test for Ticket.sol |
| [Staff.t.sol](Staff.t.sol) | Basic test for Staff.sol |
| [BuyingTicket.t.sol](BuyingTicket.t.sol) | Property based test for buying tickets |
| [BuyerUsecase.t.sol](BuyerUsecase.t.sol) | Test for buyer usecase |
| [CancellingShow.t.sol](CancellingShow.t.sol) | Test for canceling show |
| [CheckIn.t.sol](CheckIn.t.sol) | Test for check-in |
| [Withdraw.t.sol](Withdraw.t.sol) | Test for withdraw |
| [Buyer.sol](Buyer.sol) | Buyer model |
| [CONST.sol](CONST.sol) | Constants |

