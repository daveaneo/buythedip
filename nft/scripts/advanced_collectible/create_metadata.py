#!/usr/bin/python3
import os
import requests
import json
from brownie import BuyTheDipNFT, network
from metadata import sample_metadata
from scripts.helpful_scripts import get_breed
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

# breed_to_image_uri = {
#     "PUG": "https://ipfs.io/ipfs/QmSsYRx3LpDAb1GZQm7zZ1AuHZjfbPkD6J7s9r41xu1mf8?filename=pug.png",
#     "SHIBA_INU": "https://ipfs.io/ipfs/QmYx6GsYAKnNzZ9A6NvEKV9nf1VaDzJrqDR23Y8YSkebLU?filename=shiba-inu.png",
#     "ST_BERNARD": "https://ipfs.io/ipfs/QmUPjADFGEKmfohdTaNcWhp7VGk26h5jXDA7v3VtTnTLcW?filename=st-bernard.png",
# }

dip_metadata_dic = {
    0: "https://ipfs.io/ipfs/QmZeMdpQr6CQK75p55hSHRu9wKueMZYngQ4PYTHsTgskoo?filename=BuyTheDipEmpty.jpg",
    1: "https://ipfs.io/ipfs/QmVVmmaGu7eeASi9YgxAoeAA7BZjwtmiaGcT5hRsTZChVG?filename=BuyTheDipFull.jpg"
}

dip_level_to_name = {0: "empty", 1: "full"}


def main():
    print("Working on " + network.show_active())
    advanced_collectible = BuyTheDipNFT[len(BuyTheDipNFT) - 1]
    number_of_advanced_collectibles = advanced_collectible.tokenCounter()
    print(
        "The number of tokens you've deployed is: "
        + str(number_of_advanced_collectibles)
    )
    write_metadata(number_of_advanced_collectibles, advanced_collectible)


def write_metadata(token_ids, nft_contract):
    for token_id in range(token_ids):
        collectible_metadata = sample_metadata.metadata_template
        request_id = nft_contract.tokenIdToRequestId(token_id)
        dip_level = nft_contract.requestIdToDipLevel(request_id)
        dip_level_name = dip_level_to_name.get(dip_level, "")
        metadata_file_name = (
            "./metadata/{}/".format(network.show_active())
            + str(token_id)
            + "-"
            + dip_level_name
            + ".json"
        )
        if Path(metadata_file_name).exists():
            print(
                "{} already found, delete it to overwrite!".format(
                    metadata_file_name)
            )
        else:
            print("Creating Metadata file: " + metadata_file_name)
            collectible_metadata["name"] = f'Buy The Dip -- {dip_level_to_name[dip_level]}'
            if dip_level >0:
                collectible_metadata["description"] = f"Congratulations. You have bought the dip."
            else:
                collectible_metadata["description"] = f"A cool, NFT limit order that earns interest."
            image_to_upload = None
            if os.getenv("UPLOAD_IPFS") == "true":
                DYNAMIC_NFT = True # todo: do we remove storing this info?
                image_path = "./img/BuyTheDipEmpty.jpg"
                image_to_upload = upload_to_ipfs(image_path)
            image_to_upload = (
                dip_metadata_dic[dip_level] if not image_to_upload else image_to_upload
            )
            collectible_metadata["image"] = image_to_upload
            with open(metadata_file_name, "w") as file:
                json.dump(collectible_metadata, file)
            if os.getenv("UPLOAD_IPFS") == "true":
                upload_to_ipfs(metadata_file_name)

# curl -X POST -F file=@metadata/rinkeby/0-SHIBA_INU.json http://localhost:5001/api/v0/add


def upload_to_ipfs(filepath):
    with Path(filepath).open("rb") as fp:
        image_binary = fp.read()
        ipfs_url = (
            os.getenv("IPFS_URL")
            if os.getenv("IPFS_URL")
            else "http://localhost:5001"
        )
        response = requests.post(ipfs_url + "/api/v0/add",
                                 files={"file": image_binary})
        ipfs_hash = response.json()["Hash"]
        filename = filepath.split("/")[-1:][0]
        image_uri = "https://ipfs.io/ipfs/{}?filename={}".format(
            ipfs_hash, filename)
        print(image_uri)
    return image_uri
