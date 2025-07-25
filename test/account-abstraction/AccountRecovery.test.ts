import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

import { AccountRecoveryMock, RecoveryProviderMock } from "@/generated-types/ethers";
import { Reverter } from "@/test/helpers/reverter";

describe("AccountRecovery", () => {
  const reverter = new Reverter();

  let OWNER: SignerWithAddress;

  let accountRecovery: AccountRecoveryMock;
  let provider1: RecoveryProviderMock;
  let provider2: RecoveryProviderMock;

  const RECOVERY_DATA = "0x1234";

  before(async () => {
    [OWNER] = await ethers.getSigners();

    const AccountRecoveryMock = await ethers.getContractFactory("AccountRecoveryMock");
    accountRecovery = await AccountRecoveryMock.deploy();

    const RecoveryProviderMock = await ethers.getContractFactory("RecoveryProviderMock");
    provider1 = await RecoveryProviderMock.deploy();
    provider2 = await RecoveryProviderMock.deploy();

    await reverter.snapshot();
  });

  afterEach(reverter.revert);

  describe("addRecoveryProvider", () => {
    it("should add a recovery provider", async () => {
      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([]);

      const tx = await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
      await expect(tx).to.emit(accountRecovery, "RecoveryProviderAdded").withArgs(provider1);

      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([await provider1.getAddress()]);
    });

    it("should call a `subscribe` function of a recovery provider", async () => {
      const tx = await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
      await expect(tx).to.emit(provider1, "SubscribeCalled").withArgs(RECOVERY_DATA);
    });

    it("should revert if a provider is zero address", async () => {
      await expect(
        accountRecovery.addRecoveryProvider(ethers.ZeroAddress, RECOVERY_DATA),
      ).to.be.revertedWithCustomError(accountRecovery, "ZeroAddress");
    });

    it("should revert if a provider is already added", async () => {
      await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
      await expect(accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA))
        .to.be.revertedWithCustomError(accountRecovery, "ProviderAlreadyAdded")
        .withArgs(provider1);
    });
  });

  describe("removeRecoveryProvider", () => {
    beforeEach(async () => {
      await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
    });

    it("should remove a recovery provider", async () => {
      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([await provider1.getAddress()]);

      const tx = await accountRecovery.removeRecoveryProvider(provider1);
      await expect(tx).to.emit(accountRecovery, "RecoveryProviderRemoved").withArgs(provider1);

      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([]);
    });

    it("should call a `unsubscribe` function of a recovery provider", async () => {
      const tx = await accountRecovery.removeRecoveryProvider(provider1);
      await expect(tx).to.emit(provider1, "UnsubscribeCalled");
    });

    it("should revert if a provider is not added", async () => {
      await expect(accountRecovery.removeRecoveryProvider(provider2))
        .to.be.revertedWithCustomError(accountRecovery, "ProviderNotRegistered")
        .withArgs(provider2);
    });
  });

  describe("validateRecovery", () => {
    beforeEach(async () => {
      await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
    });

    it("should call a `recover` function of a recovery provider", async () => {
      const tx = await accountRecovery.validateRecovery(OWNER, provider1, RECOVERY_DATA);
      await expect(tx).to.emit(provider1, "RecoverCalled").withArgs(OWNER, RECOVERY_DATA);
    });

    it("should revert if a provider is not added", async () => {
      await expect(accountRecovery.validateRecovery(OWNER, provider2, RECOVERY_DATA))
        .to.be.revertedWithCustomError(accountRecovery, "ProviderNotRegistered")
        .withArgs(provider2);
    });

    it("should revert if a new owner is zero address", async () => {
      await expect(
        accountRecovery.validateRecovery(ethers.ZeroAddress, provider1, RECOVERY_DATA),
      ).to.be.revertedWithCustomError(accountRecovery, "ZeroAddress");
    });
  });

  describe("recoveryProviderAdded", () => {
    it("should return true if a provider is added", async () => {
      await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
      expect(await accountRecovery.recoveryProviderAdded(provider1)).to.be.true;
    });

    it("should return false if a provider is not added", async () => {
      expect(await accountRecovery.recoveryProviderAdded(provider1)).to.be.false;
    });
  });

  describe("getRecoveryProviders", () => {
    it("should return an array of recovery providers", async () => {
      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([]);

      await accountRecovery.addRecoveryProvider(provider1, RECOVERY_DATA);
      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([await provider1.getAddress()]);

      await accountRecovery.addRecoveryProvider(provider2, RECOVERY_DATA);
      expect(await accountRecovery.getRecoveryProviders()).to.be.deep.equal([
        await provider1.getAddress(),
        await provider2.getAddress(),
      ]);
    });
  });
});
