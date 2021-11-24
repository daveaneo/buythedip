#!/usr/bin/python3
# brownie test -s --network rinkeby
from brownie import BuyTheDipNFT, DipStaking, accounts, config
from scripts.helpful_scripts import get_breed, fund_with_link
import time
import pytest

test_counter = 0

def main():
    dev = accounts.add(config["wallets"]["from_key"])

    # deploy_and_create()

    print(f'BTD length: {len(BuyTheDipNFT)}')

    # Get the latest of the collectables
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    total_tokens = btd.tokenCounter()

    print(f'You have deployed {len(BuyTheDipNFT)} Collectable(s).')
    print(f'NFTs in latest deployment: {total_tokens}')

    # reset_all_dip_levels(total_tokens)
    # print(f'Dip Levels:')
    # print_all_dip_levels(total_tokens)

    test_create_collectible()

    # perform_upkeep()
    # print(f'After upkeep:')
    # print_all_dip_levels(total_tokens)

    stake_token(0)

    # set_dip_levels(set(range(btd.tokenCounter())),1)
    # side_piece()


def print_test(s):
    global test_counter
    print(f'{test_counter}) {s}')
    test_counter += 1


def test_initialize():
    # deploy_and_create()
    pass


@pytest.fixture
def deploy_and_create():
    print(f"Deploying new BuyTheDip contract, creating new collectibles.")
    dev = accounts.add(config["wallets"]["from_key"])

    # Deploy (call constructor)
    btd = BuyTheDipNFT.deploy(
        {"from": dev},
        publish_source=False,
    )

    print_test('BuyTheDip Deployed:')
    assert btd is not None

    for i in range(1):
        t = btd.createCollectible(i*15,  {"from": dev, "amount": 10**14}) # dictionary needed for payables?
        print_test('NFT Created:')
        assert t is not None

    dip_staking = DipStaking.deploy(btd.address, {"from": dev}, publish_source=False)

    perform_upkeep()


def create_collectible():
    print(f'creating new collectible.')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    num_of_collectibles = btd.tokenCounter()
    ADDITIONS = 1

    for i in range(ADDITIONS):
        t = btd.createCollectible(i * 15, {"from": dev, "amount": 10 ** 17})  # dictionary needed for payables?)

    assert t is not None
    assert num_of_collectibles + ADDITIONS is btd.tokenCounter()


def perform_upkeep():
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    print(f'Performing Upkeep...')
    btd.performUpkeepTest({"from": dev});


# def contract_and_staking_rewards(deploy_and_create):
def contract_and_staking_rewards():
    _id = 0
    print(f'Staking token {_id}')

    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]

    print(f'attempting to withdraw')

    bal_beg = dev.balance
    btd.releaseProfits({"from": dev});
    bal_end = dev.balance

    assert bal_beg == bal_end

    # Stake
    time.sleep(30)
    # See that there are rewards


# def test_stake_token(deploy_and_create):
def test_stake_token():
    _id = 0
    print(f'##### Staking Tests #####')

    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    dip_staking = DipStaking[len(DipStaking) - 1]

    # print(f'total BTDs: {len(BuyTheDipNFT)}')

    # print(f'dev: {dev}')
    # print(f'dipStaking address: {dip_staking.address}')
    # print(f'BTD address: {btd.address}')

    # btd.approve(dip_staking.address, 0, {"from": dev})

    # assume ownership. We could also mint a new token
    if btd.ownerOf(0) != dev.address:
        # btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})
        pass
        # print(f'{btd.ownerOf(0)} is not {dev}')
        # print(f'type(btd.ownerOf(0): {type(btd.ownerOf(0))}')
        # print(f'dev: {type(dev)}')
        # print(f'dev.address: {type(dev.address)}')

    else:
        # print(f'Transferring NFT to {dip_staking.address}')
        btd.safeTransferFrom(dev, dip_staking.address, _id, {"from": dev})

    time.sleep(5)
    energy = dip_staking.getTotalStakingEnergy()
    # print(f"energy: {energy}")

    print_test('Energy created in staking:')
    assert energy > 0

    # print(f"Token owner: {btd.ownerOf(0)}")
    # print(f"Previous owner: {dip_staking.previousOwner(0)}")
    # print(f'dev: {dev}')
    # print(f'dipStaking address: {dip_staking.address}')
    # print(f'BTD address: {btd.address}')

    # dip_staking.call({"value": 10000, "from": dev})
    dev.transfer(dip_staking.address, 100)
    # print(f'Balance before: {dip_staking.balance()}')
    # print(f'Unstaking and claiming rewards...')
    dip_staking.withdrawRewards(_id, {"from": dev})
    dip_staking.unstake(_id, {"from": dev})
    # print(f'Balance after: {dip_staking.balance()}')

    print_test('Unstake removes balance:')

    assert dip_staking.balance() == 0


def print_all_dip_levels(total_tokens):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    # total_tokens = btd.tokenCounter()
    for i in range(total_tokens):
        print(f'{i}) dipLevel:  {btd.tokenIdToDipLevel(i)}')


def set_dip_levels(ids, value):
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    for i in ids:
        btd.setDipLevel(i, value, {"from": dev})


def reset_all_dip_levels(total_tokens):
    # global total_tokens
    print(f'resetting... total_tokens: {total_tokens}')
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    for i in range(total_tokens):
        btd.setDipLevel(i, 0, {"from": dev})
        print(f'resetting {i}... of {total_tokens}')


def perform_upkeep():
    dev = accounts.add(config["wallets"]["from_key"])
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    print(f'Performing Upkeep...')
    btd.performUpkeepTest({"from": dev});


def side_piece():
    for i in range(len(BuyTheDipNFT)):
        if BuyTheDipNFT[i] == "0x486424aa6c5f9b90789dc6e5843581e69a89b895":
            print(f'Found at {i}')
            print(BuyTheDipNFT[i].tokenURI)
