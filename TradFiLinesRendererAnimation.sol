// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Strings.sol";
import "./Ownable.sol";
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

interface TFLAUtil {
    function attributes(Attributes memory attr, uint256 tokenId, string memory category) external view returns(string memory descriptionJson);
    function b64Encode(bytes memory _data) external pure returns (string memory result);
}
contract TradFiLinesRendererAnimation is Ownable {
    TFLAUtil public tflautil;
    constructor(address utils) {
        tflautil = TFLAUtil(utils);
    }

    // This functionality is meant to add extra svg for happenings such as Shanghai withdrawal, Arbitrum airdrop, and more
    mapping(string => string) customCategorySvg;
    function addCategory(string memory name, string memory svg) public onlyOwner {
        customCategorySvg[name] = svg;
    }
    function removeCategory(string memory name) public onlyOwner {
        delete customCategorySvg[name];
    }

    function randMod(uint _modulus, uint seed, uint secondSeed) internal view returns(uint)
    {
        return uint(keccak256(abi.encodePacked(seed, secondSeed))) % _modulus;
    }
    string[25] public chars=["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","X","Y","Z"];

    struct Candle {
        uint x1;
        uint y;
        uint open;
        uint close;
        int direction;
        uint width;
        uint height;
        string color;
        
        uint wickX;
        uint wickY;
        uint wickWidth;
        uint wickHeight;
        uint wickNumber;
        uint high;
        uint low;
    }

    struct VBoxProps {
        uint frameWidth;
        uint frameHeight;
        uint viewbox;
        uint axisLength;
    }
    function max(uint256 a, uint256 b) public pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) public pure returns (uint256) {
       return a <= b ? a : b;
    }
    function buildCandle(uint256[] memory seeds, uint previousCandleX, uint previousCandleClose, uint secondSeed, Attributes memory attr ) internal view returns(Attributes memory returnAttr, string memory svg, Candle memory newCandle, uint returnSeed) {
        newCandle.x1 = previousCandleX + 7;
        newCandle.open = previousCandleClose != 0 ? previousCandleClose : (randMod(200, seeds[0], 1) + 50);
        if(secondSeed == 1) {
            attr.startY = newCandle.open;
            if(newCandle.open > 125) {
                attr.startStatus = "Low";
            } else {
                attr.startStatus = "High";
            }
        }
        int randomNumber = 0;
        if(randMod(2, seeds[0], secondSeed + 1) == 1) {
            randomNumber = int(randMod(60, seeds[0], secondSeed + 2)) + 1;
        } else {
            randomNumber = int(randMod(30, seeds[0], secondSeed + 2)) + 1;
        }
        newCandle.direction = int(randMod(2, seeds[0], secondSeed + 3)) == 0 ? -1 : int(1);
        randomNumber *= newCandle.direction;
        if(((int(newCandle.open) + randomNumber) >= 250) || ((int(newCandle.open) + randomNumber) <= 50)) {
            randomNumber *= -1;
            newCandle.direction *= -1;
        }
        if(newCandle.direction == -1) {
            attr.greens += 1;
        } else {
            attr.reds += 1;
        }
        newCandle.y = 0;
        newCandle.width = 5;
        newCandle.height = 0;
        newCandle.close = uint(int(newCandle.open) + randomNumber);

        if((int(newCandle.open) + randomNumber) > int(newCandle.open)) {
            newCandle.y = newCandle.open;
        } else {
            newCandle.y = uint(int(newCandle.open) + randomNumber);
        }

        if(newCandle.close < newCandle.open) {
            newCandle.height = newCandle.open - newCandle.close;
        } else {
            newCandle.height = newCandle.close - newCandle.open;
        }
        newCandle.color = "green";
        if(newCandle.direction < 0) {
            newCandle.color = "green";
            attr.greenStreak += 1;
            attr.redStreak = 0;
            if(attr.greenStreak > attr.longestStreak) {
                attr.longestStreak = attr.greenStreak;
            }
        } else {
            newCandle.color = "red";
            attr.redStreak += 1;
            attr.greenStreak = 0;
            if(attr.redStreak > attr.longestStreak) {
                attr.longestStreak = attr.redStreak;
            }
        }
        newCandle.wickX = newCandle.x1 + 2;
        newCandle.wickNumber = 0;
        if(randMod(2, seeds[0], secondSeed + 4) == 0) {
            newCandle.wickNumber = randMod(40, seeds[0], secondSeed + 5);
        } else {
            newCandle.wickNumber = randMod(20, seeds[0], secondSeed + 5);
        }

        newCandle.high = max(newCandle.open, newCandle.close) + newCandle.wickNumber;
        newCandle.low = min(newCandle.open, newCandle.close);
        if((min(newCandle.open, newCandle.close) >= newCandle.wickNumber)){
            newCandle.low -= newCandle.wickNumber;
        }

        newCandle.wickHeight = newCandle.high - newCandle.low;
        newCandle.wickWidth = 1;
        uint subtractedNumber = randMod(newCandle.height > 1 ? newCandle.height : 2, seeds[0], secondSeed + 6);
        if(subtractedNumber < newCandle.y) {
            newCandle.wickY = newCandle.y - subtractedNumber;
        } else {
            newCandle.wickY = newCandle.y;
        }
        if(randMod(2, seeds[0], secondSeed + 7) == 1) {
            newCandle.wickHeight += randMod((newCandle.height > 1 ? newCandle.height : 2)/2, seeds[0], secondSeed + 8);
        }
        if(newCandle.y + newCandle.wickHeight > 250) {
            newCandle.wickHeight = 250 - newCandle.y;
        }
        returnSeed = secondSeed + 8;
        attr.lastY = newCandle.close;
        if(attr.rotationType == 0) {
            attr.whichCorner = randMod(4, seeds[0], secondSeed + 10);
        } else if (attr.rotationType == 1) {
            attr.whichCorner = randMod(6, seeds[0], secondSeed + 10);
        } else if (attr.rotationType == 2) {
            attr.whichCorner = randMod(2, seeds[0], secondSeed + 10)+4;
        }
        string memory animation;
        if(attr.whichCorner == 4) {
            animation = string(abi.encodePacked("<animateTransform attributeName='transform' attributeType='XML' type='rotate' from='360 200 200' to='0 200 200' dur='", Strings.toString(attr.mSpeed),"s' repeatCount='1'/>"));
        } else if (attr.whichCorner == 5) {
            animation = string(abi.encodePacked("<animateTransform attributeName='transform' attributeType='XML' type='rotate' from='0 200 200' to='360 200 200' dur='", Strings.toString(attr.mSpeed),"s' repeatCount='1'/>"));
        } else {
            if(attr.whichCorner == 0) {
                animation = string(abi.encodePacked("<animateMotion dur='", Strings.toString(attr.mSpeed), "s' repeatCount='1' path='M", Strings.toString(0),",", Strings.toString(0), " L", "-", Strings.toString(newCandle.x1),",", "-",Strings.toString(newCandle.y), ", L", Strings.toString(0), ",", Strings.toString(0), "' />" ));
            } else if (attr.whichCorner == 1) {
                animation = string(abi.encodePacked("<animateMotion dur='", Strings.toString(attr.mSpeed), "s' repeatCount='1' path='M", Strings.toString(0),",", Strings.toString(0), " L", "-", Strings.toString(newCandle.x1),",", Strings.toString(250-newCandle.y), ", L", Strings.toString(0), ",", Strings.toString(0), "' />" ));
            } else if (attr.whichCorner == 2) {
                animation = string(abi.encodePacked("<animateMotion dur='", Strings.toString(attr.mSpeed), "s' repeatCount='1' path='M", Strings.toString(0),",", Strings.toString(0), " L", Strings.toString(attr.axisLength+50-newCandle.x1),",", "-",Strings.toString(newCandle.y), ", L", Strings.toString(0), ",", Strings.toString(0), "' />" ));
            } else if (attr.whichCorner == 3) {
                animation = string(abi.encodePacked("<animateMotion dur='", Strings.toString(attr.mSpeed), "s' repeatCount='1' path='M", Strings.toString(0),",", Strings.toString(0), " L", Strings.toString(attr.axisLength+50-newCandle.x1),",", Strings.toString(250-newCandle.y), ", L", Strings.toString(0), ",", Strings.toString(0), "' />" ));
            }
        }
        svg = string(abi.encodePacked(svg, "<rect filter='url(#colorFilter)' x='", Strings.toString(newCandle.wickX), "' y='", Strings.toString(newCandle.wickY), "' width='", Strings.toString(newCandle.wickWidth), "' height='", Strings.toString(newCandle.wickHeight), "' fill='grey'>", animation, "</rect>"));
        svg = string(abi.encodePacked(svg, "<rect filter='url(#colorFilter)' x='", Strings.toString(newCandle.x1), "' y='", Strings.toString(newCandle.y), "' width='", Strings.toString(newCandle.width), "' height='", Strings.toString(newCandle.height), "' fill='", newCandle.color, "'>", animation, "</rect>"));
        return (attr, svg, newCandle, returnSeed);
    }

    function getTicker(uint256 seed) external view returns(string memory ticker) {
        return string(abi.encodePacked(chars[randMod(25,seed,10)], chars[randMod(25,seed,11)], chars[randMod(25,seed,12)]));
    }

    function getExchange(uint256 seed) external view returns(string memory exchange) {
        if(randMod(3, seed, 13) == 0) {
            exchange = "Nasdaq";
        } else if (randMod(3, seed, 13) == 1) {
            exchange = "NYSE";
        } else {
            exchange = "HC-Capital";
        }
    }

    function getColorScramblerType(uint256 colorSeed) external view returns(string memory feMatrixType) {
        uint typeNumber = randMod(10, colorSeed, 1);
        if(typeNumber <= 4) {
            feMatrixType = "Matrix";
        } else if (typeNumber <= 8) {
            feMatrixType = "Hue Rotate";
        } else {
            feMatrixType = "Luminance";
        }
    }

    function renderFromSeed(uint256[] memory seedsAndInfo, string memory customCategory) external view returns(string memory svg) {
        Attributes memory attr;
        string memory randomTicker = "";
        VBoxProps memory props;
        randomTicker = string(abi.encodePacked(chars[randMod(25,seedsAndInfo[0],10)], chars[randMod(25,seedsAndInfo[0],11)], chars[randMod(25,seedsAndInfo[0],12)]));
        attr.ticker = randomTicker;
        attr.rotationType = randMod(3, seedsAndInfo[0], 100);
        if(randMod(25,seedsAndInfo[0],10) == randMod(25,seedsAndInfo[0],11) && randMod(25,seedsAndInfo[0],11) == randMod(25,seedsAndInfo[0],12)) {
            attr.tickerRepetition = "Triple";
        } else if((randMod(25,seedsAndInfo[0],10) == randMod(25,seedsAndInfo[0],11)) || (randMod(25,seedsAndInfo[0],11) == randMod(25,seedsAndInfo[0],12)) || (randMod(25,seedsAndInfo[0],10) == randMod(25,seedsAndInfo[0],12))) {
            attr.tickerRepetition = "Double";
        } else {
            attr.tickerRepetition = "None";
        }
        if(randMod(3, seedsAndInfo[0], 13) == 0) {
            attr.exchange = "Nasdaq";
        } else if (randMod(3, seedsAndInfo[0], 13)== 1) {
            attr.exchange = "NYSE";
        } else {
            attr.exchange = "HC-Capital";
        }
        Candle memory newCandle;
        string memory newCandleSvg;
        uint returnSeed = 0;
        uint mSpeed = randMod(6, seedsAndInfo[2], 2 ) + 3;
        if(mSpeed > 6) {
            attr.speed = "Slow";
        } else if (mSpeed > 4) {
            attr.speed = "Normal";
        } else {
            attr.speed = "Fast";
        }
        attr.mSpeed = mSpeed;
        attr.candles = randMod(20, seedsAndInfo[0], 10) + 20 + seedsAndInfo[4];
        if(attr.candles > 120) {
            attr.candles = 120;
        }
        props.frameWidth = 500;
        props.frameHeight = 400;
        props.viewbox = 300;
        props.axisLength = 250;
        attr.axisLength = 250;
        if(attr.candles > 25) {
            props.axisLength += (attr.candles - 25) * 7;
            props.frameWidth += (attr.candles - 25) * 7;
            props.viewbox += (attr.candles - 25) * 7;
            attr.axisLength += (attr.candles - 25) * 7;
        }
        (attr, newCandleSvg, newCandle, returnSeed) = buildCandle(seedsAndInfo, 43, 0, 1, attr);

        

        //overall definition        
        svg = string(abi.encodePacked(svg,"<svg width='", Strings.toString(props.frameWidth), "' height='", Strings.toString(props.frameHeight), "' viewBox='0 0 ", Strings.toString(props.viewbox),"' fill='none' xmlns='http://www.w3.org/2000/svg'> <svg>"));
        svg = string(abi.encodePacked(svg, "<line x1='50' x2='", Strings.toString(props.axisLength), "' y1='250' y2='250' stroke='black' />", "<line x1='50' x2='50' y1='30' y2='250' stroke='black' />"));
        svg = string(abi.encodePacked(svg, "<text filter='url(#colorFilter)' x='125' y='25' fill='green'>", attr.exchange, "</text>", "<text filter='url(#colorFilter)' x='125' y='275' fill='green'>", randomTicker, "</text>"));
        svg = string(abi.encodePacked(svg, newCandleSvg));
        for(uint256 i = 0; i < attr.candles; i++) {
            (attr, newCandleSvg, newCandle, returnSeed) = buildCandle(seedsAndInfo, newCandle.x1, newCandle.close, returnSeed, attr);
            svg = string(abi.encodePacked(svg, newCandleSvg));
        }
        svg = string(abi.encodePacked(svg, "</svg>"));
        if(bytes(customCategorySvg[customCategory]).length > 0) {
            svg = string(abi.encodePacked(svg, customCategorySvg[customCategory]));
        }
        
        if(seedsAndInfo[5] == 1) {
            attr.place = 1;
            svg = string(abi.encodePacked(svg, "<polygon xmlns='http://www.w3.org/2000/svg' style='fill:#EFCE4A;' points='76.934,251.318 85.256,268.182 103.867,270.887 90.4,284.013 93.579,302.549 76.934,293.798   60.288,302.549 63.467,284.013 50,270.887 68.611,268.182' />"));
        } else if(seedsAndInfo[5] == 2) {
            attr.place = 2;
            svg = string(abi.encodePacked(svg, "<polygon xmlns='http://www.w3.org/2000/svg' style='fill:#C0C0C0;' points='76.934,251.318 85.256,268.182 103.867,270.887 90.4,284.013 93.579,302.549 76.934,293.798   60.288,302.549 63.467,284.013 50,270.887 68.611,268.182' />"));
        } else if (seedsAndInfo[5] == 3) {
            attr.place = 3;
            svg = string(abi.encodePacked(svg, "<polygon xmlns='http://www.w3.org/2000/svg' style='fill:#CD7F32;' points='76.934,251.318 85.256,268.182 103.867,270.887 90.4,284.013 93.579,302.549 76.934,293.798   60.288,302.549 63.467,284.013 50,270.887 68.611,268.182' />"));
        }

        if(seedsAndInfo[6] == 1) {
            attr.animationPlace = 1;
            svg = string(abi.encodePacked(svg, "<polygon xmlns='http://www.w3.org/2000/svg' style='fill:#EFCE4A;' points='76.934,311.318 85.256,328.182 103.867,330.887 90.4,344.013 93.579,362.549 76.934,353.798   60.288,362.549 63.467,344.013 50,330.887 68.611,328.182' />"));
        } else if(seedsAndInfo[6] == 2) {
            attr.animationPlace = 2;
            svg = string(abi.encodePacked(svg, "<polygon xmlns='http://www.w3.org/2000/svg' style='fill:#EFCE4A;' points='76.934,311.318 85.256,328.182 103.867,330.887 90.4,344.013 93.579,362.549 76.934,353.798   60.288,362.549 63.467,344.013 50,330.887 68.611,328.182' />"));
        } else if (seedsAndInfo[6] == 3) {
            attr.animationPlace = 3;
            svg = string(abi.encodePacked(svg, "<polygon xmlns='http://www.w3.org/2000/svg' style='fill:#EFCE4A;' points='76.934,311.318 85.256,328.182 103.867,330.887 90.4,344.013 93.579,362.549 76.934,353.798   60.288,362.549 63.467,344.013 50,330.887 68.611,328.182' />"));
        }   

        if(attr.lastY > attr.startY) {
            attr.result = "Down Bad";
        } else {
            attr.result = "Up Only";
        }
        if(attr.greens > attr.reds) {
            attr.dominantColor = "Green";
        } else {
            attr.dominantColor = "Red";
        }
        if(randMod(10, seedsAndInfo[2], 1) <= 4) {
            attr.feMatrixType = "Matrix";
        } else if (randMod(10, seedsAndInfo[2], 1) <= 8) {
            attr.feMatrixType = "Hue Rotate";
        } else {
            attr.feMatrixType = "Luminance";
        }

        
        string memory colorSvg = colorProperties(seedsAndInfo[1], randMod(10, seedsAndInfo[2], 1));
        string memory descriptionSvg = tflautil.attributes(attr, seedsAndInfo[4], customCategory); 
        svg = string(abi.encodePacked(svg, colorSvg));
        svg = string(abi.encodePacked(svg, '</svg>'));
        //svg = string(abi.encodePacked('data:application/json;ascii,','{"image": "data:image/svg+xml;base64,', svg, '",',descriptionSvg));

        svg = string(abi.encodePacked('data:application/json;ascii,','{"image": "data:image/svg+xml;base64,', tflautil.b64Encode(bytes(svg)), '",',descriptionSvg));
        return svg;
    }

    function colorProperties(uint256 colorSeed, uint256 typeNumber) public view returns(string memory colorJson) {
        colorJson = string(abi.encodePacked(colorJson, '<filter id="colorFilter"><feColorMatrix in="SourceGraphic" '));
        if(typeNumber <= 4) {
            colorJson = string(abi.encodePacked(colorJson, 'type="matrix" values="'));
            for(uint256 i = 0; i < 19; i++) {
                colorJson = string(abi.encodePacked(colorJson, '0.', Strings.toString(randMod(70, colorSeed, i)), ' '));
            }
                colorJson = string(abi.encodePacked(colorJson, '1 '));
        } else if (typeNumber <= 8) {
            colorJson = string(abi.encodePacked(colorJson, 'type="hueRotate" values="', Strings.toString(randMod(300, colorSeed, 3) + 30)));
        } else if (typeNumber == 9) {
            colorJson = string(abi.encodePacked(colorJson, 'type="luminanceToAlpha'));
        }
        colorJson = string(abi.encodePacked(colorJson, '" /></filter>'));
    }
    
}