import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import { contractAbi, contractAddress } from './Constant/constant';
import Login from './Components/Login';
import Connected from './Components/Connected';
import Finished from './Components/Finished';
import './App.css';

function App() {
  const [provider, setProvider] = useState(null);
  const [account, setAccount] = useState(null);
  const [isConnected, setIsConnected] = useState(false);
  const [votingStatus, setVotingStatus] = useState(true);
  const [remainingTime, setremainingTime] = useState('');
  const [formatTime, setformatTime] = useState('');
  const [candidates, setCandidates] = useState([]);
  const [number, setNumber] = useState('');
  const [CanVote, setCanVote] = useState(true);


  useEffect(() => {
    getCandidates();
    getRemainingTime();
    getCurrentStatus();
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', handleAccountsChanged);
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', handleAccountsChanged);
      }
    }
  });


  async function vote() {
    const provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer =await provider.getSigner();
    const contractInstance = new ethers.Contract(
      contractAddress, contractAbi, signer
    );

    const tx = await contractInstance.vote(number);
    await tx.wait();
    canVote();
  }


  async function canVote() {
    const provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer = await provider.getSigner();
    const contractInstance = new ethers.Contract(
      contractAddress, contractAbi, signer
    );
    const voteStatus = await contractInstance.voters(await signer.getAddress());
    setCanVote(voteStatus);

  }

  async function getCandidates() {
    const provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer =await provider.getSigner();
    const contractInstance = new ethers.Contract(
      contractAddress, contractAbi, signer
    );
    const candidatesList = await contractInstance.getAllVotesOfCandiates();
    const formattedCandidates = candidatesList.map((candidate, index) => {
      return {
        index: index,
        name: candidate.name,
        voteCount: Number(candidate.voteCount)
      }
    });
    setCandidates(formattedCandidates);
  }


  async function getCurrentStatus() {
    const provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer =await provider.getSigner();
    const contractInstance = new ethers.Contract(
      contractAddress, contractAbi, signer
    );
    const status = await contractInstance.getVotingStatus();
    setVotingStatus(status);
  }

  async function getRemainingTime() {
    const provider = new ethers.BrowserProvider(window.ethereum);
    await provider.send("eth_requestAccounts", []);
    const signer =await provider.getSigner();
    const contractInstance = new ethers.Contract(
      contractAddress, contractAbi, signer
    );
    const time = await contractInstance.getRemainingTime();
    const seconds = Number(time);
    setremainingTime(seconds);
    const StandardTime= (seconds) => {
      const h = Math.floor(seconds / 3600);
      const m = Math.floor((seconds % 3600) / 60);
      const s = seconds % 60;
      return `${h}h ${m}m ${s}s`; // 转换为 00h 00m 00s 格式
    };
    setformatTime(StandardTime(seconds))
  }

  function handleAccountsChanged(accounts) {
    if (accounts.length > 0 && account !== accounts[0]) {
      setAccount(accounts[0]);
      canVote();
    } else {
      setIsConnected(false);
      setAccount(null);
    }
  }

  async function connectToMetamask() {
    if (window.ethereum) {
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        setProvider(provider);
        await provider.send("eth_requestAccounts", []);
        const signer = await provider.getSigner();
        const address = await signer.getAddress();
        setAccount(address);
        console.log("Metamask Connected : " + address);
        setIsConnected(true);
        canVote();
      } catch (err) {
        console.error(err);
      }
    } else {
      console.error("Metamask is not detected in the browser")
    }
  }

  async function handleNumberChange(e) {
    setNumber(e.target.value);
  }

  return (
    <div className="App">
      {votingStatus ? (isConnected ? (<Connected
        account={account}
        candidates={candidates}
        remainingTime={formatTime}
        number={number}
        handleNumberChange={handleNumberChange}
        voteFunction={vote}
        showButton={CanVote} />) : (<Login connectWallet={connectToMetamask} />)) : (<Finished />)}

    </div>
  );
}

export default App;
