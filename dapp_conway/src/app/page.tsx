'use client';

import React, { useState, useEffect } from "react";
import { BrowserProvider, Contract } from "ethers";
import Link from "next/link";

import token from "../contracts/Token.json";
import address from "../contracts/address.json";

const CONTRACT_ABI = token.abi;
const CONTRACT_ADDRESS = address.Token;

export default function Home() {
    const [nfts, setNfts] = useState<{ id: number; image: string; animation: string }[]>([]);
    const [loading, setLoading] = useState(false);
    const [minting, setMinting] = useState(false);
    const [lineLength, setLineLength] = useState<number>(0);
    const [bits, setBits] = useState<string>("");

    const fetchNFTs = async () => {
        try {
            if (!window.ethereum) throw new Error("No crypto wallet found");

            const provider = new BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            const address = await signer.getAddress();
            const contract = new Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

            const ownedNFTIds = [];
            const ownerNFTCount = await contract.balanceOf(address);
            let count = 0, i = 0;
            while (count < ownerNFTCount) {
                if (await contract.ownerOf(i) === address) {
                    ownedNFTIds.push(i);
                    count++;
                }
                i++;
            }

            const nftData = await Promise.all(
                ownedNFTIds.map(async (id) => {
                    const tokenUri = await contract.tokenURI(id);
                    const base64Data = tokenUri.split(",")[1];
                    const metadata = JSON.parse(atob(base64Data));

                    return {
                        id,
                        image: atob(metadata.image.split(",")[1]),
                        animation: atob(metadata.animation_url.split(",")[1]),
                    };
                })
            );

            setNfts(nftData);
        } catch (err: any) {
            alert(err.message || "Failed to fetch NFTs");
        }
    };

    const mintNFT = async () => {
        try {
            if (!window.ethereum) throw new Error("No crypto wallet found");

            const provider = new BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            const contract = new Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

            setMinting(true);
            const bitsArray = bits.split(",").map((b) => parseInt(b, 10));
            const transaction = await contract.safeMint(await signer.getAddress(), lineLength, bitsArray);
            await transaction.wait();

            alert("NFT Minted Successfully!");
            fetchNFTs();
        } catch (err: any) {
            alert(err.message || "An error occurred");
        } finally {
            setMinting(false);
        }
    };

    useEffect(() => {
        fetchNFTs();
    }, []);

    return (
        <div className="min-h-screen bg-black text-white p-4 relative overflow-hidden">
            <div className="relative z-10">
                <h1 className="text-5xl font-extrabold text-center mb-8">
                    <span className="bg-gradient-to-r from-green-400 via-blue-500 to-purple-600 text-transparent bg-clip-text">
                        Conway's Game of NFTs
                    </span>
                </h1>

                <div className="flex justify-center mb-12">
                    <div className="bg-gray-800 p-6 rounded-lg shadow-lg border border-green-500">
                        <h2 className="text-3xl font-bold mb-6 text-center">Mint a New NFT</h2>
                        <div className="mb-4">
                            <label className="block mb-2 font-semibold">Line Length:</label>
                            <input
                                type="number"
                                className="w-full p-2 bg-gray-900 border border-green-400 rounded focus:outline-none"
                                value={lineLength}
                                onChange={(e) => setLineLength(Number(e.target.value))}
                            />
                        </div>
                        <div className="mb-6">
                            <label className="block mb-2 font-semibold">Bits (comma-separated):</label>
                            <input
                                type="text"
                                className="w-full p-2 bg-gray-900 border border-green-400 rounded focus:outline-none"
                                value={bits}
                                onChange={(e) => setBits(e.target.value)}
                            />
                        </div>
                        <button
                            onClick={mintNFT}
                            disabled={minting}
                            className="w-full py-2 px-4 bg-green-500 rounded hover:bg-green-600 font-bold transition"
                        >
                            {minting ? "Minting..." : "Mint NFT"}
                        </button>
                    </div>
                </div>

                <h2 className="text-4xl font-bold text-center mb-8">Your NFTs</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-6 gap-6">
                    {nfts.map((nft) => (
                        <Link href={`/nft/${nft.id}`} key={nft.id}>
                            <div className="bg-gray-800 p-4 rounded-lg shadow-lg border border-blue-500 hover:scale-105 transform transition">
                                <h3 className="text-2xl font-semibold text-center mb-4">
                                    NFT #{nft.id}
                                </h3>
                                <div
                                    className="relative aspect-square bg-black rounded-lg overflow-hidden border border-green-500"
                                    dangerouslySetInnerHTML={{ __html: nft.image }}
                                ></div>
                            </div>
                        </Link>
                    ))}
                </div>
            </div>
        </div>
    );
}
