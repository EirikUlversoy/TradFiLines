pragma solidity ^0.8.17;
import "./Strings.sol";

contract TFLAUtil {

    struct Attributes {
        string result; // downbad or uponly
        string description;
        uint reds;
        uint greens;
        uint candles;
        string exchange;
        string ticker;
        string tickerRepetition; // 1, 2, 3
        string startStatus; // high, low
        uint startY;
        uint lastY;
        uint redStreak;
        uint greenStreak;
        uint longestStreak;
        string dominantColor;
        string feMatrixType;
        uint place;
        uint animationPlace;
        string speed;
        uint mSpeed;
        uint whichCorner;
        uint axisLength;
        uint rotationType;

    }
    function attributes(Attributes memory attr, uint256 tokenId, string memory category) external view returns(string memory descriptionJson) {
        descriptionJson = string(abi.encodePacked(descriptionJson,'"name": "TradFiLines-A ', Strings.toString(tokenId), '","description":"Randomly generated stock charts, tickers and exchanges. This third wrapper introduces three types of animation, with varying speeds. Corners, rotation and mixed. Standard mechanics: These NFTs can only be traded within regular NYSE/Nasdaq trading hours. This means they are not transferrable on weekends, and only from 9:30 to 16:00 every day. Every transfer of the NFT adds a candle and changes the metadata",' ));
        descriptionJson = string(abi.encodePacked(descriptionJson,'"attributes": [ { "trait_type": "Start Type", "value":"', attr.startStatus, '"},{"trait_type": "Ticker Repetition", "value":"',attr.tickerRepetition));
        descriptionJson = string(abi.encodePacked(descriptionJson,'"},{"trait_type": "Result", "value":"', attr.result,'"},{"trait_type": "Ticker", "value":"', attr.ticker));
        descriptionJson = string(abi.encodePacked(descriptionJson,'"},{"trait_type": "Candles", "value":', Strings.toString(attr.candles),'},{"trait_type": "Green Bars", "value":', Strings.toString(attr.greens)));
        descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Red Bars", "value":', Strings.toString(attr.reds)));
        descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Animation Speed", "value":"', attr.speed));
        descriptionJson = string(abi.encodePacked(descriptionJson,'"},{"trait_type": "Longest Streak", "value":', Strings.toString(attr.longestStreak)));
        if(bytes(category).length > 0) {
            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "', category, '", "value": "true"'));
        }
        if(attr.place >= 1) {
            string memory colorStar;
            if(attr.place == 1) {
                colorStar = "Gold";
            } else if (attr.place == 2) {
                colorStar = "Silver";
            } else if (attr.place == 3) {
                colorStar = "Bronze";
            }

            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "PlaceC", "value":', Strings.toString(attr.place)));
            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "StarC", "value":', Strings.toString(attr.place)));

        }
        if(attr.animationPlace >= 1) {
            string memory animationStar;
            if(attr.animationPlace == 1) {
                animationStar = "Gold";
            } else if (attr.animationPlace == 2) {
                animationStar = "Silver";
            } else if (attr.animationPlace == 3) {
                animationStar = "Bronze";
            }

            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "PlaceM", "value":', Strings.toString(attr.place)));
            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "StarM", "value":', Strings.toString(attr.place)));
        }
        if(attr.rotationType == 0) {
            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Rotation Type", "value":"Corners"'));
        } else if (attr.rotationType == 1) {
            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Rotation Type", "value":"Mixed"'));
        } else if (attr.rotationType == 2) {
            descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Rotation Type", "value":"Rotation"'));
        }
        descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Fe Matrix Type", "value":"', attr.feMatrixType, '"'));
        descriptionJson = string(abi.encodePacked(descriptionJson,'},{"trait_type": "Exchange", "value":"', attr.exchange,'"},{"trait_type": "Dominant Color", "value":"', attr.dominantColor, '"}]}'));
        return descriptionJson;
    }

    string constant private TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function b64Encode(bytes memory _data) external pure returns (string memory result) {
        if (_data.length == 0) return '';
        string memory _table = TABLE;
        uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
        result = new string(_encodedLen + 32);

        assembly {
            mstore(result, _encodedLen)
            let tablePtr := add(_table, 1)
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))
            let resultPtr := add(result, 32)

            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(_data), 3)
            case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
            case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
        }
        return result;
    }
}

