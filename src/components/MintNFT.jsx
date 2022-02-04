import NativeBalance from "./NativeBalance";
import Address from "./Address/Address";
import Blockie from "./Blockie";
import { Card, Button, Modal } from "antd";
import { useState } from "react";
import { useMoralisDapp } from "providers/MoralisDappProvider/MoralisDappProvider";
import { useWeb3ExecuteFunction } from "react-moralis";
import { Steps } from 'antd';

const styles = {
  title: {
    fontSize: "30px",
    fontWeight: "600",
  },
  header: {
    display: "flex",
    flexDirection: "column",
    alignItems: "center",
  },
  card: {
    boxShadow: "0 0.5rem 1.2rem rgb(189 197 209 / 20%)",
    border: "1px solid #e7eaf3",
    borderRadius: "1rem",
    width: "450px",
    fontSize: "16px",
    fontWeight: "500",
  },

  steps_action: {
    marginTop: "24px",
  }
};

function MintNFT() {
    const { marketAddress, contractABI } = useMoralisDapp();
    const [isPending, setIsPending] = useState(false);
    const contractProcessor = useWeb3ExecuteFunction();
    const contractABIJson = JSON.parse(contractABI);
    const createItemFunction = "create";
    const { Step } = Steps;
    const [status, setStatus] = useState("wait");

    function succList() {
        let secondsToGo = 5;
        const modal = Modal.success({
          title: "Success!",
          content: `Your NFT is minted, you can look it in your collections`,
        });
        setTimeout(() => {
          modal.destroy();
        }, secondsToGo * 1000);
      }
    
      function failList() {
        let secondsToGo = 5;
        const modal = Modal.error({
          title: "Error!",
          content: `There was a problem minting your NFT`,
        });
        setTimeout(() => {
          modal.destroy();
        }, secondsToGo * 1000);
      }

    async function mint() {
        setIsPending(true);
        setStatus("process")
        const p = 1 * ("1e" + 13);
        const ops = {
            contractAddress: marketAddress,
            functionName: createItemFunction,
            abi: contractABIJson,
            params: {},
            msgValue: p
    };

    await contractProcessor.fetch({
        params: ops,
        onSuccess: () => {
            console.log("success");
            setIsPending(false);
            succList();
            setStatus("finish")
    },
    onError: (error) => {
        setIsPending(false);
        failList();
    },
    });
    }

    return (

    <div>
    <Card
      style={styles.card}
      title={
        <div style={styles.header}>
          <Blockie scale={5} avatar currentWallet />
          <Address size="6" copyable />
          <NativeBalance />
        </div>
      }
    >

    <Button
          type="primary"
          size="large"
          loading={isPending}
          style={{ width: "100%", marginTop: "0px", marginBottom:"20px" }}
          onClick={() => mint()}
        >
        Mint Now 👾
    </Button>

    <Steps direction="vertical" size="small">
      <Step status={status} title="Mint Token" description="mint NFT Token" />
      <Step status={status} title="Generate Art" description="Randomly generate art work for your NFT" />
      <Step status={status} title="Finish" description="see your NFT in your collection" />
    </Steps>
    </Card>
  </div>

    

  );
}

export default MintNFT;





      
