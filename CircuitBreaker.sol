// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";
import "./Ownable.sol";

interface BokkyPooBahsDateTimeContract {
    function timestampToDateTime(uint timestamp) external returns (uint year, uint month, uint day, uint hour, uint minute, uint second);
    function addHours(uint timestamp, uint _hours) external returns (uint newTimestamp);
    function subHours(uint timestamp, uint _hours) external returns (uint newTimestamp);
}
interface AggregatorV3Interface {
  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract CircuitBreaker is Ownable {
    address private _owner;
    BokkyPooBahsDateTimeContract public bpbdtc;
    AggregatorV3Interface internal CO;
    mapping(uint => bool) public haltedDays;
    event BreakerTripped(uint indexed percentageChange, address indexed nftOracleAddress, uint indexed date);

    address public nftOracleAddress;
    int public lastValue;
    uint public lastTimestamp;
    uint public haltPercentage; 
    bool public incentivizedUpdates = false;
    bool public incentivizedBreaker = true;
    uint public incentiveBreakerValue = 0.01 ether;
    uint public incentiveUpdatesValue = 0.001 ether;
    uint public hoursToSub;
    uint public hoursToAdd;

    constructor(address timeLibraryAddress, address nftOracleAddress, uint hoursToAddInput, uint hoursToSubInput, uint haltPercentageInput) {
        _transferOwnership(_msgSender());
        CO = AggregatorV3Interface(nftOracleAddress);
        //nftOracleAddress = 0x352f2Bc3039429fC2fe62004a1575aE74001CfcE; // Default to bored apes
        bpbdtc = BokkyPooBahsDateTimeContract(timeLibraryAddress);
        haltPercentage = haltPercentageInput;
        hoursToSub = hoursToSubInput;
        hoursToAdd = hoursToAddInput;
        int currentValue;
        uint updatedAt;
        (,currentValue,,,updatedAt) = CO.latestRoundData(); 
        lastTimestamp = updatedAt;
        lastValue = currentValue; 
    }

    function swapOracle(address newOracleAddress) public onlyOwner {
        uint timestamp = getAdjustedTimestamp();
        uint year;
        uint month;
        uint day;
        (year, month, day, , , ) = bpbdtc.timestampToDateTime(timestamp);
        uint date = year * 10000 + month * 100 + day;

        require(haltedDays[date] == false, "Not allowed to change oracle while the CircuitBreaker is tripped");
        CO = AggregatorV3Interface(newOracleAddress);
    }

    // Functions to adjust timezones.
    function setHoursToSub(uint newHoursToSub) public onlyOwner {
        hoursToSub = newHoursToSub;
    }

    function setHoursToAdd(uint newHoursToAdd) public onlyOwner {
        hoursToAdd = newHoursToAdd;
    }

    function updateIncentiveUpdatesValue(uint newIncentiveValue) public onlyOwner {
        incentiveUpdatesValue = newIncentiveValue;
    }

    function updateIncentiveBreakerValue(uint newIncentiveValue) public onlyOwner {
        incentiveBreakerValue = newIncentiveValue;
    }

    function setIncentivizedBreaker(bool incentivizedValue) public onlyOwner {
        incentivizedBreaker = incentivizedValue;
    }

    function setIncentivizedUpdates(bool incentivizedValue) public onlyOwner {
        incentivizedUpdates = incentivizedValue;
    }

    function setPercentageThreshold(uint newPercentage) public onlyOwner {
        // Minimum 2 to prevent breaking too often
        require(newPercentage >= 2, "The threshold value is not allowed to be below 2%");
        haltPercentage = newPercentage;
    }

    function getAdjustedTimestamp() public returns(uint timestamp) {
        if(hoursToAdd > 0) {
            return bpbdtc.addHours(block.timestamp, hoursToAdd);
        } else if (hoursToSub > 0) {
            return bpbdtc.subHours(block.timestamp, hoursToSub);
        }
    }

    function isHalted() external returns(bool halted) {
        uint timestamp = getAdjustedTimestamp();
        uint year;
        uint month;
        uint day;
        (year, month, day, , , ) = bpbdtc.timestampToDateTime(timestamp);
        return haltedDays[year * 10000 + month * 100 + day];
    }

    function revertOnHalted() external {
        uint timestamp = getAdjustedTimestamp();
        uint year;
        uint month;
        uint day;
        (year, month, day, , , ) = bpbdtc.timestampToDateTime(timestamp);
        require(haltedDays[year * 10000 + month * 100 + day] == false, "Circuit breaker triggered: Transfer functionality has been halted.");
    }

    function setValue() external {
        int currentValue;
        uint updatedAt;
        (,currentValue,,,updatedAt) = CO.latestRoundData(); 
        require(lastValue != currentValue);
        require(updatedAt - lastTimestamp > 1000*60*60*12, "The value can only be updated after 12 hours. If the price moves a lot before 12 hours have passed, the breaker should be called");
        lastTimestamp = updatedAt;
        lastValue = currentValue; 
        // Incentivizing updates is expensive. This should be off by default.
        if(incentivizedUpdates && address(this).balance >= incentiveUpdatesValue) {
            (bool sent, bytes memory data) = payable(msg.sender).call{value: incentiveUpdatesValue}("");
        }
    }
    function tripBreaker() external {
        require(lastValue != 0, "Value never initialized");
        int currentValue;
        uint updatedAt;
        (,currentValue,,,updatedAt) = CO.latestRoundData(); 

        int256 difference = currentValue - lastValue;
        int percentageChange = 0;
        uint timestamp = getAdjustedTimestamp();
        uint year;
        uint month;
        uint day;
        (year, month, day, , , ) = bpbdtc.timestampToDateTime(timestamp);
        uint date = year * 10000 + month * 100 + day;

        require(haltedDays[date] == false, "CircuitBreaker already tripped");

        if(difference < 0) {
            percentageChange = (difference * 100) / currentValue;
        } else if (difference > 0) {
            percentageChange = (difference * 100) / lastValue;
        }
        if(uint(percentageChange) > haltPercentage) {
            haltedDays[date] = true;
            lastValue = currentValue;
            lastTimestamp = updatedAt;
            if(incentivizedBreaker && address(this).balance >= incentiveBreakerValue) {
                (bool sent, bytes memory data) = payable(msg.sender).call{value: incentiveBreakerValue}("");
            }
 
            emit BreakerTripped(uint(percentageChange), nftOracleAddress, date);
        }
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}