import React, { useState, useEffect, use } from "react";
import { ethers, Signer } from 'ethers';

const Healthcare = () => {
    const [provider, setProvider] = useState(null);
    const [signer, setSigner] = useState(null);
    const [contract, setContract] = useState(null);
    const [account, setAccount] = useState(null);
    const [isOwner, setIsOwner] = useState(null);
    const [patientID, setPatientID] = useState('');
    const [diagnosis, setDiagnosis] = useState('');
    const [treatment, setTreatment] = useState('');
    const [patientRecords, setPatientRecords] = useState([]);


    const [providerAddress, setProviderAddress] = useState("");
    const contractAddress = "0x2e8623c8801c02418653e11ff1bbc190536cfd3d";

    const contractABI = [
        {
            "inputs": [],
            "stateMutability": "nonpayable",
            "type": "constructor"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "patientID",
                    "type": "uint256"
                },
                {
                    "internalType": "string",
                    "name": "patientName",
                    "type": "string"
                },
                {
                    "internalType": "string",
                    "name": "diagnosis",
                    "type": "string"
                },
                {
                    "internalType": "string",
                    "name": "treatment",
                    "type": "string"
                }
            ],
            "name": "addRecord",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "address",
                    "name": "provider",
                    "type": "address"
                }
            ],
            "name": "authorizedProvider",
            "outputs": [],
            "stateMutability": "nonpayable",
            "type": "function"
        },
        {
            "inputs": [],
            "name": "getOwner",
            "outputs": [
                {
                    "internalType": "address",
                    "name": "",
                    "type": "address"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [
                {
                    "internalType": "uint256",
                    "name": "patientID",
                    "type": "uint256"
                }
            ],
            "name": "getPatientRecords",
            "outputs": [
                {
                    "components": [
                        {
                            "internalType": "uint256",
                            "name": "recordID",
                            "type": "uint256"
                        },
                        {
                            "internalType": "string",
                            "name": "patientName",
                            "type": "string"
                        },
                        {
                            "internalType": "string",
                            "name": "diagnosis",
                            "type": "string"
                        },
                        {
                            "internalType": "string",
                            "name": "treatment",
                            "type": "string"
                        },
                        {
                            "internalType": "uint256",
                            "name": "timestamp",
                            "type": "uint256"
                        }
                    ],
                    "internalType": "struct HealthcareRecords.Record[]",
                    "name": "",
                    "type": "tuple[]"
                }
            ],
            "stateMutability": "view",
            "type": "function"
        }
    ];

    useEffect(() => {
        const connectWallet = async () => {
            try {
                const provider = new ethers.providers.Web3Provider(window.ethereum);
                await provider.send('eth_requestAccounts', []);
                const signer = provider.getSigner();
                setProvider(provider);
                setSigner(signer);

                const accountAddress = await signer.getAddress();
                setAccount(accountAddress);

                console.log(accountAddress);

                const contract = new ethers.Contract(contractAddress, contractABI, signer);
                setContract(contract);

                const ownerAddress = await contract.getOwner();

                setIsOwner(accountAddress.toLowerCase() === ownerAddress.toLowerCase());


            } catch (error) {
                console.error("Error connecting to wallet: ", error);
            }

        };
        connectWallet();

    }, []);


    const fetchPatientRecords = async () => {
        try {
            const records = await contract.getPatientRecords(patientID);
            console.log(records);
            setPatientRecords(records);

        } catch (error) {
            console.error("Error fetching patient records", error);
        }
    }

    const addRecord = async () => {
        try {
            const tx = await contract.addRecord(patientID, "Alice", diagnosis, treatment);
            await tx.wait();
            fetchPatientRecords();
            await tx.wait();
            alert(`Provider ${providerAddress} authorized successfully`);

        } catch (error) {
            console.error("Error adding records", error);
        }

    }


    const authorizeProvider = async () => {
        if (isOwner) {
            try {
                const tx = await contract.authorizedProvider(providerAddress);
                await tx.wait();
                alert(`Provider ${providerAddress} authorized successfully`);

            } catch (error) {
                console.error("Only contract owner can authorize different providers");
            }
        } else {
            alert("Only contract owner can call this function");
        }
    }

    return (
        <div className='container'>
            <h1 className="title">HealthCare Application</h1>
            {account && <p className='account-info'>Connected Account: {account}</p>}
            {isOwner && <p className='owner-info'>You are the contract owner</p>}
            <div>
                <div className='form-section'>
                    <h2>Fetch Patient Records</h2>
                    <input className='input-field' type='text' placeholder='Enter Patient ID' value={patientID} onChange={(e) => setPatientID(e.target.value)} />
                    <button className='action-button' onClick={fetchPatientRecords}>Fetch Records</button>
                </div>

                <div className="form-section">
                    <h2>Add Patient Record</h2>
                    <input className='input-field' type='text' placeholder='Diagnosis' value={diagnosis} onChange={(e) => setDiagnosis(e.target.value)} />
                    <input className='input-field' type='text' placeholder='Treatment' value={treatment} onChange={(e) => setTreatment(e.target.value)} />
                    <button className='action-button' onClick={addRecord}>Add Records</button>

                </div>
                <div className="form-section">
                    <h2>Authorize HealthCare Provider</h2>
                    <input className='input-field' type="text" placeholder='Provider Address' value={providerAddress} onChange={(e) => setProviderAddress(e.target.value)} />
                    <button className='action-button' onClick={authorizeProvider}>Authorize Provider</button>
                </div>

                <div className='medical-record-card'>
                    <div class="card-header">
                        <h2>Medical Record</h2>
                    </div>
                    {patientRecords.map((record, index) => (
                        <div class="card-body" key={index}>
                            <div class="record-item">
                                <span class="label">Record ID:</span>
                                <span class="value">{record.recordID.toNumber()}</span>
                            </div>
                            <div class="record-item">
                                <span class="label">Diagnosis:</span>
                                <span class="value">{record.diagnosis}</span>
                            </div>
                            <div class="record-item">
                                <span class="label">Treatment:</span>
                                <span class="value">{record.treatment}</span>
                            </div>
                            <div class="record-item">
                                <span class="label">Time:</span>
                                <span class="value">{new Date(record.timestamp.toNumber() * 1000).toLocaleString()}</span>
                            </div>
                            <hr />
                        </div>
                    ))}
                </div>
            </div>
        </div>

    )

}

export default Healthcare;