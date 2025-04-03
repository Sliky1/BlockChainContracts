import { pinata } from './config';
import { useState } from "react";
import { ethers } from "ethers";
import './App.css';

function App() {
  const [selectedFile, setSelectedFile] = useState(null);
  const [ipfsTable, setIpfsTable] = useState([]);
  const [ipfsHash, setIpfsHash] = useState("");
  const [storedHash, setStoredHash] = useState("");
  const CONTRACT_ADDRESS = "0xedc2cd85a546fb8357a426715690ebdd27706d17";
  const CONTRACT_ABI = [
    {
      "inputs": [
        {
          "internalType": "string",
          "name": "_ipfshash",
          "type": "string"
        }
      ],
      "name": "setIPFSHash",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getIPFSHash",
      "outputs": [
        {
          "internalType": "string",
          "name": "",
          "type": "string"
        }
      ],
      "stateMutability": "view",
      "type": "function"
    }
  ];

  const changeHandler = (event) => {
    setSelectedFile(event.target.files[0]);
  };

  const handleSubmission = async () => {
    try {
      if (!selectedFile) {
        console.error("No file selected");
        return;
      }
      const response = await pinata.upload.public.file(selectedFile);
      const ipfsTable = [response.cid, response.size, response.created_at];
      const ipfsHash = ipfsTable[0]
      setIpfsTable(ipfsTable);
      setIpfsHash(ipfsHash);
      await storeHashOnBlockchain(ipfsHash);
    } catch (error) {
      console.log("File upload failed:", error);
    }
  };

  const storeHashOnBlockchain = async (hash) => {
    try {
      // Connect to Ethereum provider (MetaMask)
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      // Create a contract instance
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
      // Send the transaction to store the IPFS hash on the blockchain
      const tx = await contract.setIPFSHash(hash);
      await tx.wait();
      console.log("IPFS hash stored on blockchain:", hash);
    } catch (error) {
      console.log("Failed to store IPFS hash on blockchain:", error);
    }
  };

  const retrieveHashFromBlockchain = async () => {
    try {
      // Connect to Ethereum provider (MetaMask)
      const provider = new ethers.BrowserProvider(window.ethereum);
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, provider);
      // Retrieve the IPFS hash from the blockchain
      const retrievedHash = await contract.getIPFSHash();
      setStoredHash(retrievedHash);
      console.log("Retrieved IPFS hash from blockchain:", retrievedHash);
    } catch (error) {
      console.log("Failed to retrieve IPFS hash from blockchain:", error);
    }
  };

  return (
    <div className="app-container">
      <div className="upload-section">
        <label className="form-label">Choose File</label>
        <input type="file" onChange={changeHandler} className="file-input" />
        <button onClick={handleSubmission} className="submit-button">
          Submit
        </button>
      </div>

      {ipfsHash && (
        <div className="result-section">
          <label className="form-label">IPFS</label>
          <p><strong>CID:</strong> {ipfsTable[0]}</p>
          <p><strong>FIEL SIZE:</strong> {ipfsTable[1]}</p>
          <p><strong>CREATE TIME:</strong> {ipfsTable[2]}</p>
        </div>
      )}

      <div className="retrieve-section">
        <button onClick={retrieveHashFromBlockchain} className="retrieve-button">
          Retrieve Stored Hash
        </button>
        {storedHash && (
          <p>
            <strong>Stored IPFS Hash:</strong> {storedHash}
          </p>
        )}
      </div>
    </div>
  );
}

export default App;