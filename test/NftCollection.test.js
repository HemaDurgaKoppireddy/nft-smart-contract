const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NftCollection", () => {
    let nft, owner, alice, bob;

    beforeEach(async () => {
        [owner, alice, bob] = await ethers.getSigners();

        const NFT = await ethers.getContractFactory("NftCollection");

        // FIXED: maxSupply changed from 5 → 1000
        nft = await NFT.deploy(
            "MyNFT",
            "MNFT",
            1000,  // <--- UPDATED
            "https://example.com/meta/"
        );

        await nft.deployed();
    });

    // ------------------------------------------------------------
    //                   INITIAL CONFIGURATION
    // ------------------------------------------------------------

    it("should initialize with correct name, symbol, maxSupply", async () => {
        expect(await nft.name()).to.equal("MyNFT");
        expect(await nft.symbol()).to.equal("MNFT");
        expect(await nft.maxSupply()).to.equal(1000);  // updated
        expect(await nft.totalSupply()).to.equal(0);
    });

    // ------------------------------------------------------------
    //                           MINTING
    // ------------------------------------------------------------

    it("admin should mint successfully", async () => {
        await expect(nft.safeMint(alice.address, 1))
            .to.emit(nft, "Transfer")
            .withArgs(ethers.constants.AddressZero, alice.address, 1);

        expect(await nft.ownerOf(1)).to.equal(alice.address);
        expect(await nft.totalSupply()).to.equal(1);
        expect(await nft.balanceOf(alice.address)).to.equal(1);
    });

    it("non-admin should NOT be able to mint", async () => {
        await expect(
            nft.connect(alice).safeMint(alice.address, 1)
        ).to.be.revertedWith("Only admin");
    });

    it("should NOT mint to zero address", async () => {
        await expect(
            nft.safeMint(ethers.constants.AddressZero, 2)
        ).to.be.revertedWith("Mint to zero");
    });

    it("should NOT mint same token twice", async () => {
        await nft.safeMint(alice.address, 1);
        await expect(
            nft.safeMint(alice.address, 1)
        ).to.be.revertedWith("Already minted");
    });

    it("should NOT mint beyond maxSupply", async () => {
        await expect(
            nft.safeMint(alice.address, 2000)
        ).to.be.revertedWith("tokenId out of range");
    });

    it("should pause and unpause minting", async () => {
        await nft.pauseMinting();

        await expect(
            nft.safeMint(alice.address, 10)
        ).to.be.revertedWith("Minting paused");

        await nft.unpauseMinting();

        await nft.safeMint(alice.address, 10);

        expect(await nft.ownerOf(10)).to.equal(alice.address);
    });

    // ------------------------------------------------------------
    //                           TRANSFERS
    // ------------------------------------------------------------

    it("owner should transfer token", async () => {
        await nft.safeMint(alice.address, 10);

        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, 10)
        )
            .to.emit(nft, "Transfer")
            .withArgs(alice.address, bob.address, 10);

        expect(await nft.ownerOf(10)).to.equal(bob.address);
    });

    it("approved address should transfer token", async () => {
        await nft.safeMint(alice.address, 11);

        await nft.connect(alice).approve(bob.address, 11);

        await nft.connect(bob).transferFrom(alice.address, bob.address, 11);

        expect(await nft.ownerOf(11)).to.equal(bob.address);
    });

    it("operator should transfer token", async () => {
        await nft.safeMint(alice.address, 12);

        await nft.connect(alice).setApprovalForAll(bob.address, true);

        await nft.connect(bob).transferFrom(alice.address, bob.address, 12);

        expect(await nft.ownerOf(12)).to.equal(bob.address);
    });

    it("should fail transferring nonexistent token", async () => {
        await expect(
            nft.connect(alice).transferFrom(alice.address, bob.address, 999)
        ).to.be.revertedWith("Nonexistent token");
    });

    it("should fail transferring when not owner or approved", async () => {
        await nft.safeMint(alice.address, 20);

        await expect(
            nft.connect(bob).transferFrom(alice.address, bob.address, 20)
        ).to.be.revertedWith("Not approved");
    });

    // ------------------------------------------------------------
    //                        APPROVALS
    // ------------------------------------------------------------

    it("should approve address for a token", async () => {
        await nft.safeMint(alice.address, 30);

        await expect(
            nft.connect(alice).approve(bob.address, 30)
        )
            .to.emit(nft, "Approval")
            .withArgs(alice.address, bob.address, 30);

        expect(await nft.getApproved(30)).to.equal(bob.address);
    });

    it("should set operator approval", async () => {
        await expect(
            nft.connect(alice).setApprovalForAll(bob.address, true)
        )
            .to.emit(nft, "ApprovalForAll")
            .withArgs(alice.address, bob.address, true);

        expect(await nft.isApprovedForAll(alice.address, bob.address)).to.equal(true);
    });

    it("should NOT approve nonexistent token", async () => {
        await expect(
            nft.connect(alice).approve(bob.address, 1234)
        ).to.be.revertedWith("Nonexistent token");
    });

    it("should NOT allow approving self as operator", async () => {
        await expect(
            nft.connect(alice).setApprovalForAll(alice.address, true)
        ).to.be.revertedWith("Operator is sender");
    });

    // ------------------------------------------------------------
    //                        METADATA
    // ------------------------------------------------------------

    it("tokenURI should return correct full URI", async () => {
        await nft.safeMint(alice.address, 40);
        expect(await nft.tokenURI(40)).to.equal("https://example.com/meta/40");
    });

    it("tokenURI should revert for nonexistent token", async () => {
        await expect(
            nft.tokenURI(777)
        ).to.be.revertedWith("Nonexistent token");
    });

    // ------------------------------------------------------------
    //                      EDGE CASE CHECKS
    // ------------------------------------------------------------

    it("balanceOf should revert on zero address", async () => {
        await expect(
            nft.balanceOf(ethers.constants.AddressZero)
        ).to.be.revertedWith("Zero address");
    });

    it("ownerOf should revert for nonexistent token", async () => {
        await expect(
            nft.ownerOf(999)
        ).to.be.revertedWith("Nonexistent token");
    });

    // Optional burn tests
    it("owner can burn and totalSupply decrements", async () => {
        await nft.safeMint(alice.address, 50);

        await nft.connect(alice).burn(50);

        await expect(
            nft.ownerOf(50)
        ).to.be.revertedWith("Nonexistent token");

        expect(await nft.totalSupply()).to.equal(0);
    });
});
