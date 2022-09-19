// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
// imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// errors
error FundMe__NotOwner();

// interfaces, Libraries, Contracts
/** @title A contract for crowd founding
 *  @author Franco Aguilera
 *  @notice This is a demo contract
 *  @dev This implements price feeds to our library
 */
contract FundMe {
  // type declarations
  using PriceConverter for uint256;

  // state variables
  mapping(address => uint256) public addressToAmountFunded;
  address[] public funders;
  // could we make this constant ?
  address public immutable i_owner;
  uint256 public constant MINIMUM_USD = 50 * 10**18;
  AggregatorV3Interface public priceFeed;

  // state modifiers
  modifier onlyOwner() {
    // require(msg.sender == owner);
    if (msg.sender != i_owner) revert FundMe__NotOwner();
    _;
  }

  constructor(address priceFeedAddress) {
    i_owner = msg.sender;
    priceFeed = AggregatorV3Interface(priceFeedAddress);
  }

  fallback() external payable {
    fund();
  }

  receive() external payable {
    fund();
  }

  /**
   *  @notice This function funds this contract
   *  @dev This implements price feeds to our library
   */
  function fund() public payable {
    require(
      msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,
      "You need to spend more ETH!"
    );
    addressToAmountFunded[msg.sender] += msg.value;
    funders.push(msg.sender);
  }

  function withdraw() public payable onlyOwner {
    for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) {
      address funder = funders[funderIndex];
      addressToAmountFunded[funder] = 0;
    }
    funders = new address[](0);
    (bool callSuccess, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    require(callSuccess, "Call failed");
  }
}
