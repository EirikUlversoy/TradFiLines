// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./OperatorFilterer.sol";
import "./ERC2981.sol";

interface Cryptokitties {
    function balanceOf(address owner) external returns (uint256 balance);
}

interface Maneki {
    function balanceOf(address owner) external returns (uint256 balance);
}

interface NCT {
    function balanceOf(address owner) external returns (uint256 balance);
}

interface BPDTL {
    function getMinute(uint timestamp) external returns (uint minute);
}
contract ChallengeA is ERC721, ERC721Enumerable, Ownable, ERC2981, OperatorFilterer {
    bool public operatorFilteringEnabled;
    uint public maxSupply = 5;
    Cryptokitties public cryptokitties;
    Maneki public maneki;
    NCT public nct;
    BPDTL public bpdtl;
    constructor() ERC721("Challenge-A", "C-A") {
        cryptokitties = Cryptokitties(0x06012c8cf97BEaD5deAe237070F9587f8E7A266d);
        maneki = Maneki(0x14f03368B43E3a3D27d45F84FabD61Cc07EA5da3);
        nct = NCT(0x8A9c4dfe8b9D8962B31e4e16F8321C44d48e246E);
        bpdtl = BPDTL(0x78F96B2D5F717fa9ad416957B79D825cc4ccE69d);
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function reserve(uint256 n) public onlyOwner {
      uint supply = totalSupply();
      require(supply + n <= maxSupply, "Would exceed max tokens");
      for (uint i = 0; i < n; i++) {
        _mint(msg.sender, supply + i);
      }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override(ERC721, IERC721) onlyAllowedOperator(from) {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }
    
    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }    

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
   
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    receive() external payable {}
    
    function solve(uint answer) external {
        uint supply = totalSupply();
        require(supply < maxSupply);
        uint minute = bpdtl.getMinute(block.timestamp);
        require(answer == 208918, "Answer is missing");
        require(minute == 7, "lucky 7");
        require(cryptokitties.balanceOf(msg.sender) > 0, "Something is missing");
        require(nct.balanceOf(msg.sender) > 0, "Something is missing");
        require(maneki.balanceOf(msg.sender) > 0, "Something is missing");
        require(balanceOf(msg.sender) == 0, "One per address");
        _mint(msg.sender, supply);
        (bool sent, bytes memory data) = payable(msg.sender).call{value: 0.20 ether}("");
        require(sent, "Failed to send Ether");
    }
    string public _baseTokenURI = "https://flares.mypinata.cloud/ipfs/QmazM7r81ZLmcqfBNDp1Jk2jTDFibU19ke3rD7jqvoVnjU/";
    string public _baseTokenExtension = ".json"; 

    function setBaseTokenURI(string memory __baseTokenURI) public onlyOwner {
        _baseTokenURI = __baseTokenURI;
    }

    function setTokenExtension(string memory __baseTokenExtension) public onlyOwner {
        _baseTokenExtension = __baseTokenExtension;
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

        string(
                abi.encodePacked(
                    _baseTokenURI,
                    Strings.toString(_tokenId),
                    _baseTokenExtension
                )
            );
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
}