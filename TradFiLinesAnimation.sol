// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

interface TradFiRendererAnimation {
    function renderFromSeed(uint256[] memory seedsAndInfo, string memory customCategory) external view returns(string memory svg);
}

interface TradFiLines {
    function ownerOf(uint256 tokenId) external view returns(address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenIdToSeed(uint256 seed) external view returns(uint256);
    function tokenIdToCount(uint256 seed) external view returns(uint256);
}

interface TradFiLinesColor {
    function ownerOf(uint256 tokenId) external view returns(address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function tokenIdToSeed(uint256 tokenId) external view returns(uint256);
    function tokenIdToCount(uint256 tokenId) external view returns(uint256);
    function tokenIdToPlacement(uint256 tokenId) external view returns(uint256);
    function colorTokenIdToSeed(uint256 tokenId) external view returns(uint256);
}

interface CircuitBreaker {
    function isHalted() external view returns(bool halted);
    function revertOnHalted() external view;
}

interface BokkyPooBahsDateTimeContract {
    function timestampToDateTime(uint timestamp) external returns (uint year, uint month, uint day, uint hour, uint minute, uint second);
    function isWeekEnd(uint timestamp) external returns (bool weekEnd);
    function getMonth(uint timestamp) external returns (uint month);
    function getDay(uint timestamp) external returns (uint day);
    function subHours(uint timestamp, uint _hours) external returns (uint newTimestamp);
    function getDayOfWeek(uint timestamp) external returns (uint dayOfWeek);
}

contract TradFiLinesAnimation is ERC721, ERC721Enumerable, Ownable {
    mapping (uint => uint) public tokenIdToCount;
    mapping (uint => uint) public tokenIdToSeed;
    mapping (uint => uint) public tokenIdToSeedAnimation;
    mapping (uint => uint) public tokenIdToPlacement;
    mapping (uint => mapping(uint => bool)) public bribedHour;
    mapping (uint => uint) public dayToPlace;
    mapping (uint => string) public idToCategory;
    address public tradFiRenderer;
    uint public bribeAmount = 0.01 ether;
    bool public bribeStatus = true;
    bool public prizesActive = true;
    bool public bribesActive = true;
    TradFiRendererAnimation public tfrm;
    TradFiLinesColor public tflColor;
    TradFiLines public tfl;
    BokkyPooBahsDateTimeContract public bpbdtc; 
    CircuitBreaker public cb;

    constructor(address tradFiRenderer, address tradFiLines, address tradFiLinesColor, address circuitBreakerAddress, address bokkyPooBahsDateTimeContractAddress) ERC721("TradFiLines-M", "TFL-M") {
        tfrm = TradFiRendererAnimation(tradFiRenderer);
        tflColor = TradFiLinesColor(tradFiLinesColor);
        tfl = TradFiLines(tradFiLines);
        cb = CircuitBreaker(circuitBreakerAddress);
        bpbdtc = BokkyPooBahsDateTimeContract(bokkyPooBahsDateTimeContractAddress);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function changeBribeAmount(uint newBribeAmount) external onlyOwner {
        bribeAmount = newBribeAmount;
    }

    function setPrizes(bool prizesBool) external onlyOwner {
        prizesActive = prizesBool;
    }
    
    bool public isDST = false;
    uint public hoursToSub = 5;
    function adjustDST() external {
        uint timestamp = bpbdtc.subHours(block.timestamp, hoursToSub);
        uint month = bpbdtc.getMonth(timestamp);
        if(month > 3 && month < 11) {
            isDST = true;
        } else {
            uint day = bpbdtc.getDayOfWeek(timestamp);
            uint dayOfMonth = bpbdtc.getDay(timestamp);
            if(month == 3) {
                if(dayOfMonth > 14) {
                    isDST = true;
                } else if(dayOfMonth < 8) {
                    isDST = false;
                } else {
                    if((dayOfMonth - day - 7) < 1) {
                        isDST = false;
                    } else {
                        isDST = true;
                    }
                }
            }
            if(month == 11) {
                if(dayOfMonth > 7) {
                    isDST = false;
                } else {
                    if((dayOfMonth - day) < 1) {
                        isDST = true;
                    } else {
                        isDST = false;
                    }
                }
            }
        }
        if(isDST) {
            hoursToSub = 4;
        } else {
            hoursToSub = 5;
        }
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        require(isWithinOpeningHours(), "Outside regular trading hours");
        require(!cb.isHalted(), "Circuit breaker triggered: Transfer functionality has been halted.");
        tokenIdToCount[tokenId] += 1;
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function getAdjustedTimestamp() public returns(uint timestamp) {
        return bpbdtc.subHours(block.timestamp, hoursToSub);
    } 

    function isWithinBribedHour(uint year, uint month, uint hour, uint day) public view returns(bool) {
        return bribedHour[year][month * 10000 + day * 100 + hour];
    }
    function bribe(uint year, uint month, uint day, uint hour) payable external {
        require(!bribedHour[year][month * 10000 + day * 100 + hour], "This hour is already bribed for and open");
        require(msg.value > bribeAmount, string(abi.encodePacked("The required bribe amount is ", Strings.toString(bribeAmount))));
        bribedHour[year][month * 10000 + day * 100 + hour] = true;
    }

    function isTradingOpen() public returns(bool){
        return isWithinOpeningHours() && !cb.isHalted();
    }

    function setBribeStatus(bool newBribeStatus) public onlyOwner {
        bribeStatus = newBribeStatus;
    }
    function isWithinOpeningHours() public returns(bool){
        uint timestamp = getAdjustedTimestamp();        
        bool weekend = bpbdtc.isWeekEnd(timestamp);
        uint hour;
        uint year;
        uint month;
        uint day;
        uint minute;
        (year, month, day, hour, minute, ) = bpbdtc.timestampToDateTime(timestamp);
        
        bool wasBribed = isWithinBribedHour(year, month, day, hour);
        if(wasBribed) {
            return true;
        }
        if(weekend) {
            return false;
        }

        if(hour < 9 || hour > 15) {
            return false;
        }
        if(hour == 9 && minute < 30) {
            return false;
        }

        return true;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    receive() external payable {}
    
    function wrap(uint tokenToWrap) external {
        uint timestamp = getAdjustedTimestamp();
        uint year;
        uint month;
        uint day;
        (year, month, day, , , ) = bpbdtc.timestampToDateTime(timestamp);

        tflColor.safeTransferFrom(msg.sender, address(this), tokenToWrap);
        tokenIdToCount[tokenToWrap] = tflColor.tokenIdToCount(tokenToWrap);
        if(tokenIdToSeedAnimation[tokenToWrap] == 0 ) {
            tokenIdToSeedAnimation[tokenToWrap] = uint(keccak256(abi.encodePacked(blockhash(block.number-1),tokenToWrap)));
        }
        if(tokenIdToPlacement[tokenToWrap] == 0) {
            uint place = dayToPlace[day + month * 100 + year * 10000] += 1;
            tokenIdToPlacement[tokenToWrap] = place;
            if(prizesActive) {
                uint prize = 0;
                if(place == 1) {
                    prize = 0.10 ether;
                } else if(place == 2) {
                    prize = 0.05 ether;
                } else {
                    prize = 0.015 ether;
                }
                if(prize > 0 && address(this).balance >= prize) {
                    (bool sent, bytes memory data) = payable(msg.sender).call{value: prize}("");
                    require(sent, "Failed to send Ether");
                }
            }
        }
        _mint(msg.sender, tokenToWrap);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(_tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        ); 
        uint256 seed = tfl.tokenIdToSeed(_tokenId);
        uint256 colorSeed = tflColor.colorTokenIdToSeed(_tokenId);
        uint256[] memory seedsAndInfo = new uint[](7);
        seedsAndInfo[0] = seed;
        seedsAndInfo[1] = colorSeed;
        seedsAndInfo[2] = tokenIdToSeedAnimation[_tokenId];
        seedsAndInfo[3] = tokenIdToCount[_tokenId];
        seedsAndInfo[4] = _tokenId;
        seedsAndInfo[5] = tflColor.tokenIdToPlacement(_tokenId);
        seedsAndInfo[6] = tokenIdToPlacement[_tokenId];

        return
            string(
                abi.encodePacked(
                    tfrm.renderFromSeed(seedsAndInfo, idToCategory[_tokenId])
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}