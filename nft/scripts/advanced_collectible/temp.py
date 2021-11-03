#!/usr/bin/python3
from brownie import BuyTheDipNFT, accounts, config
from scripts.helpful_scripts import get_breed, fund_with_link
import time


def main():
    dev = accounts.add(config["wallets"]["from_key"])

    print(f'You have deployed {len(BuyTheDipNFT)} Collectable(s).')

    # Get the latest of the collectables
    # print(f'Total number of collectibles: {len(BuyTheDipNFT)}')
    btd = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    total_tokens = btd.tokenCounter()

    print(f'NFTs in latest deployment: {total_tokens}')

    # reset_all_dip_levels(total_tokens)
    print(f'Dip Levels:')
    print_all_dip_levels(total_tokens)
    perform_upkeep()
    print(f'After upkeep:')
    print_all_dip_levels(total_tokens)

    # set_dip_levels(set(range(btd.tokenCounter())),1)

    # side_piece()

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
