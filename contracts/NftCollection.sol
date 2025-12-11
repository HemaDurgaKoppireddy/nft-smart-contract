// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title NftCollection - full ERC-721 style contract implemented from scratch
/// @notice Includes admin, minting, approvals, metadata, pause, transfer pause, burn, ERC165, safe transfers
contract NftCollection {
    // -----------------------------------------------------------
    //                      State Variables
    // -----------------------------------------------------------

    string private _name;
    string private _symbol;

    uint256 public immutable maxSupply;
    uint256 public totalSupply;

    // Admin + pause flags
    address public admin;
    bool public mintPaused;
    bool public transfersPaused;

    // Storage: ERC-721 mappings
    mapping(uint256 => address) private _owners;      // tokenId => owner
    mapping(address => uint256) private _balances;    // owner => balance
    mapping(uint256 => address) private _tokenApprovals; 
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Metadata base URI
    string private _baseTokenURI;

    // -----------------------------------------------------------
    //                           Events
    // -----------------------------------------------------------

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event TransfersPaused(address indexed account);
    event TransfersUnpaused(address indexed account);

    // ERC165 interface ids
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    // ERC721Receiver selector
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // -----------------------------------------------------------
    //                          Modifiers
    // -----------------------------------------------------------

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    modifier whenMintNotPaused() {
        require(!mintPaused, "Minting paused");
        _;
    }

    modifier whenTransfersNotPaused() {
        require(!transfersPaused, "Transfers paused");
        _;
    }

    // -----------------------------------------------------------
    //                        Constructor
    // -----------------------------------------------------------

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_,
        string memory baseURI_
    ) {
        require(maxSupply_ > 0, "maxSupply>0");

        _name = name_;
        _symbol = symbol_;
        maxSupply = maxSupply_;
        _baseTokenURI = baseURI_;

        admin = msg.sender;
        mintPaused = false;
        transfersPaused = false;
    }

    // -----------------------------------------------------------
    //                         ERC165
    // -----------------------------------------------------------

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == _INTERFACE_ID_ERC165
            || interfaceId == _INTERFACE_ID_ERC721
            || interfaceId == _INTERFACE_ID_ERC721_METADATA;
    }

    // -----------------------------------------------------------
    //                        Read Functions
    // -----------------------------------------------------------

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "Zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Nonexistent token");
        return owner;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "Nonexistent token");
        return string(abi.encodePacked(_baseTokenURI, _toString(tokenId)));
    }

    function getApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId), "Nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator) external view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    // -----------------------------------------------------------
    //                       Admin Functions
    // -----------------------------------------------------------

    function pauseMinting() external onlyAdmin {
        mintPaused = true;
        emit Paused(msg.sender);
    }

    function unpauseMinting() external onlyAdmin {
        mintPaused = false;
        emit Unpaused(msg.sender);
    }

    function pauseTransfers() external onlyAdmin {
        transfersPaused = true;
        emit TransfersPaused(msg.sender);
    }

    function unpauseTransfers() external onlyAdmin {
        transfersPaused = false;
        emit TransfersUnpaused(msg.sender);
    }

    function setBaseURI(string calldata newBaseURI) external onlyAdmin {
        _baseTokenURI = newBaseURI;
    }

    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "new admin zero");
        emit AdminTransferred(admin, newAdmin);
        admin = newAdmin;
    }

    // -----------------------------------------------------------
    //                           Minting
    // -----------------------------------------------------------

    function safeMint(address to, uint256 tokenId)
        external
        onlyAdmin
        whenMintNotPaused
    {
        require(to != address(0), "Mint to zero");
        require(!_exists(tokenId), "Already minted");
        require(tokenId >= 1 && tokenId <= maxSupply, "tokenId out of range");

        totalSupply += 1;
        _owners[tokenId] = to;
        _balances[to] += 1;

        emit Transfer(address(0), to, tokenId);
    }

    // -----------------------------------------------------------
    //                         Approvals
    // -----------------------------------------------------------

    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(to != owner, "Approve to owner");

        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "Not owner nor operator"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != msg.sender, "Operator is sender");

        _operatorApprovals[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // -----------------------------------------------------------
    //                          Transfers
    // -----------------------------------------------------------

    function transferFrom(address from, address to, uint256 tokenId)
        public
        whenTransfersNotPaused
    {
        _transfer(from, to, tokenId, msg.sender);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        external
        whenTransfersNotPaused
    {
        _transfer(from, to, tokenId, msg.sender);
        _checkOnERC721Received(msg.sender, from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        external
        whenTransfersNotPaused
    {
        _transfer(from, to, tokenId, msg.sender);
        _checkOnERC721Received(msg.sender, from, to, tokenId, data);
    }

    function _transfer(address from, address to, uint256 tokenId, address caller) internal {
        require(ownerOf(tokenId) == from, "Not owner");
        require(to != address(0), "Transfer to zero");
        require(_isApprovedOrOwner(caller, tokenId), "Not approved");

        // Clear approval
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
            emit Approval(from, address(0), tokenId);
        }

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    // -----------------------------------------------------------
    //                             Burn
    // -----------------------------------------------------------

    function burn(uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not owner nor approved");

        // Clear approval
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
            emit Approval(owner, address(0), tokenId);
        }

        _balances[owner] -= 1;
        delete _owners[tokenId];
        totalSupply -= 1;

        emit Transfer(owner, address(0), tokenId);
    }

    // -----------------------------------------------------------
    //                   Internal Utility Functions
    // -----------------------------------------------------------

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        address owner = _owners[tokenId];
        return (
            spender == owner ||
            _tokenApprovals[tokenId] == spender ||
            _operatorApprovals[owner][spender]
        );
    }

    // ERC721Receiver check
    function _checkOnERC721Received(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal view {
        uint256 size;
        assembly {
            size := extcodesize(to)
        }

        if (size == 0) return; // EOA

        (bool success, bytes memory returndata) = to.staticcall(
            abi.encodeWithSelector(
                _ERC721_RECEIVED,
                operator,
                from,
                tokenId,
                data
            )
        );

        require(
            success &&
            returndata.length >= 4 &&
            bytes4(returndata) == _ERC721_RECEIVED,
            "Transfer to non ERC721Receiver"
        );
    }

    // uint256 -> string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 digits;
        uint256 temp = value;

        while (temp != 0) {
            digits++;
            temp /= 10;
        }

        bytes memory buffer = new bytes(digits);

        while (value != 0) {
            digits--;
            buffer[digits] = bytes1(uint8(48 + value % 10));
            value /= 10;
        }

        return string(buffer);
    }
}
