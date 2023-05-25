// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IWhitelist.sol";

contract CryptoDevs is ERC721Enumerable, Ownable {
    /**
      * @dev _baseTokenURI for computing {tokenURI}. If set, the resulting URI for each
      * token will be the concatenation of the `baseURI` and the `tokenId`.
      */
    //ABC_1, ABC_2, ABC_3, ABC_4, ABC_5 이런식으로 숫자가 붙는다
    //이 숫자 앞에 붙는게 baseTokenURI
    string _baseTokenURI;

    //  _price is the price of one Crypto Dev NFT
    // 하나당 NFT의 가격
    uint256 public _price = 0.01 ether;

    // _paused is used to pause the contract in case of an emergency
    // 가끔 긴급 상황이 발생하면 컨트랙트를 일시정지 시킬 수 있다
    bool public _paused;

    // max number of CryptoDevs
    // 총 20개 발행
    uint256 public maxTokenIds = 20;

    // total number of tokenIds minted
    //현재 민팅된 갯수
    uint256 public tokenIds;

    // Whitelist contract instance
    // 화이트 리스트관련 인터페이스
    IWhitelist whitelist;

    // boolean to keep track of whether presale started or not
    // 프리세일 시작 시간
    bool public presaleStarted;

    // timestamp for when presale would end
    //퍼블릭 세일 시작 시간(프리세일 끝나는 시간)
    uint256 public presaleEnded;

    modifier onlyWhenNotPaused {
        require(!_paused, "Contract currently paused");
        _;
    }

    /**
     * 
      * @dev ERC721 constructor takes in a `name` and a `symbol` to the token collection.
      * name in our case is `Crypto Devs` and symbol is `CD`.
      * Constructor for Crypto Devs takes in the baseURI to set _baseTokenURI for the collection.
      * It also initializes an instance of whitelist interface.
      * 컨트렉트 최소 실행시 실행되는 함수
      */
    constructor (string memory baseURI, address whitelistContract) ERC721("Crypto Devs", "CD") {
        _baseTokenURI = baseURI;
        whitelist = IWhitelist(whitelistContract);
    }

    /**
    * @dev startPresale starts a presale for the whitelisted addresses
      */
    function startPresale() public onlyOwner {
        presaleStarted = true;
        // Set presaleEnded time as current timestamp + 5 minutes
        // Solidity has cool syntax for timestamps (seconds, minutes, hours, days, years)
        presaleEnded = block.timestamp + 5 minutes;
    }

    /**
      * @dev presaleMint allows a user to mint one NFT per transaction during the presale.
      */
    function presaleMint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp < presaleEnded, "Presale is not running");
        require(whitelist.whitelistedAddresses(msg.sender), "You are not whitelisted"); // 화이트 리스트에 등록된 사람만 구매 가능
        require(tokenIds < maxTokenIds, "Exceeded maximum Crypto Devs supply"); // 최대 갯수 확인
        require(msg.value >= _price, "Ether sent is not correct"); // 돈이 부족한지 확인
        tokenIds += 1; // 민팅 끝났으면 1 추가
        //_safeMint is a safer version of the _mint function as it ensures that
        // if the address being minted to is a contract, then it knows how to deal with ERC721 tokens
        // If the address being minted to is not a contract, it works the same way as _mint
        _safeMint(msg.sender, tokenIds);
    }

    /**
    * @dev mint allows a user to mint 1 NFT per transaction after the presale has ended.
    */
   // 보면 화이트 리스트만 없다 프리세일이 아니기 떄문에 다 구매 가능
    function mint() public payable onlyWhenNotPaused {
        require(presaleStarted && block.timestamp >=  presaleEnded, "Presale has not ended yet");
        require(tokenIds < maxTokenIds, "Exceed maximum Crypto Devs supply");
        require(msg.value >= _price, "Ether sent is not correct");
        tokenIds += 1;
        _safeMint(msg.sender, tokenIds);
    }

    /**
    * @dev _baseURI overrides the Openzeppelin's ERC721 implementation which by default
    * returned an empty string for the baseURI
    */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
    * @dev setPaused makes the contract paused or unpaused
      */
    function setPaused(bool val) public onlyOwner {
        _paused = val;
    }

    /**
    * @dev withdraw sends all the ether in the contract
    * to the owner of the contract
      */
     // NFT를 구매하면 내 계좌가 아닌 컨트렉트에 돈이 모인다
     // 그 돈을 내 계좌로 보내는 함수
    function withdraw() public onlyOwner  {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

      // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}