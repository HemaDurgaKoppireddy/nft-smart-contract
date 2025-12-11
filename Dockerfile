FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .

# Compile contracts
RUN npx hardhat compile

# Run tests by default
CMD ["npx", "hardhat", "test"]
