'use client';

import React, { useEffect, useState } from "react";
import { BrowserProvider, Contract } from "ethers";
import { useParams } from "next/navigation"; // Fetch params in a client component

import token from "../../../contracts/Token.json";
import address from "../../../contracts/address.json";

const CONTRACT_ABI = token.abi;
const CONTRACT_ADDRESS = address.Token;

type Props = {
    params: {
        id: string;
    };
};

const NFTPage = ({ params }: {
    params: Promise<{ id: string; }>;
}) => {
    const [nftData, setNftData] = useState<any>(null);
    const { id } = useParams();

    const fetchNFT = async (tokenId: string) => {
        try {
            if (!window.ethereum) throw new Error("No crypto wallet found");

            const provider = new BrowserProvider(window.ethereum); // Updated for ethers v6
            const signer = await provider.getSigner();
            const contract = new Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

            const tokenURI = await contract.tokenURI(tokenId);
            console.log(tokenURI);
            const base64Data = tokenURI.split(",")[1];
            const metadata = JSON.parse(atob(base64Data));
            setNftData(atob(metadata.animation_url.split(",")[1]));
        } catch (err: any) {
            console.error(err.message || "Failed to fetch NFT");
        }
    };

    useEffect(() => {
        if (id) fetchNFT(id as string);
    }, [id]);

    if (!nftData) return <div>Loading NFT...</div>;

    return (
        <div>
            <h1>NFT Details</h1>
            <iframe srcDoc={nftData} width="100%" height="500px" />
        </div>
    );
};

export default NFTPage;
