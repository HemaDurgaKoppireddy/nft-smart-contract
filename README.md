# NftCollection — ERC-721 Assignment

## Overview

This repository contains a minimal ERC-721 style NFT smart contract implemented from scratch (no OpenZeppelin), a complete automated test suite, and a Dockerfile so tests can run reproducibly inside a container.

Contents:
- contracts/NftCollection.sol — NFT contract (admin, mint, transfer, approvals, metadata, pause, burn)
- test/NftCollection.test.js — Full test suite (Mocha/Chai + Hardhat)
- Dockerfile — Build and run tests in a container
- .dockerignore
- package.json
- hardhat.config.js
- README.md



## File structure

+------------------------------+--------------------------------------------------------------+
| Path / File                  | Description                                                  |
+------------------------------+--------------------------------------------------------------+
| contracts/                   | Solidity contracts directory                                 |
| └── NftCollection.sol        | Main ERC-721 style NFT contract (mint, transfer, approve)    |
+------------------------------+--------------------------------------------------------------+
| test/                        | Hardhat test directory                                       |
| └── NftCollection.test.js    | Full automated test suite (21 tests)                         |
+------------------------------+--------------------------------------------------------------+
| Dockerfile                   | Builds image and runs tests inside Docker                    |
| .dockerignore                | Files/folders excluded from Docker context                   |
+------------------------------+--------------------------------------------------------------+
| hardhat.config.js            | Hardhat configuration (solidity version, plugins, mocha)     |
| package.json                 | Project dependencies, scripts                                |
| package-lock.json            | Locked dependency versions                                   |
| README.md                    | Project documentation                                        |
+------------------------------+--------------------------------------------------------------+
| node_modules/                | Installed dependencies (auto-generated)                      |
+------------------------------+--------------------------------------------------------------+




## Quick start (Local)

Build and run tests locally:

npm ci
npx hardhat compile
npx hardhat test



## Docker usage

Build Docker image:

docker build -t nft-contract .

Run tests inside Docker:

docker run --rm nft-contract

Expected output:

21 passing



## Features

- Admin-only minting
- Transfers and safe transfers
- Approvals and operator approvals
- BaseURI + tokenId metadata generation
- Pause minting / pause transfers
- Burn tokens
- Full revert checks
- Full automated test coverage (21 tests)
