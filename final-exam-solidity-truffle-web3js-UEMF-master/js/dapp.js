import { fundingContractConfig } from "./config.js";
let web3;
let fundingContract;

const main = async () => {
    if (window.ethereum == undefined)
        return alert("Please install MetaMask or any other compatible Ethereum provider");
        console.log("MetaMask or other providers are installed");
    try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        const myAddress = await getMyAddress();
        document.getElementById("myAddressEle").innerText = myAddress;

        web3 = new Web3(window.ethereum);
        fundingContract = new web3.eth.Contract(fundingContractConfig.ABI, fundingContractConfig.address);

        await loadProjects();

    } catch (e) {
        alert(e.message);
    }
};

const loadProjects = async () => {
    const projectCount = await fundingContract.methods.projectCount().call();
    const container = document.getElementById("container");
    container.innerHTML = "";

    for (let i = 1; i <= projectCount; i++) {
        const project = await fundingContract.methods.projects(i).call();
        const donors = await fundingContract.methods.getProjectDonors(i).call();
        let totalDonations = 0;
        for (const donor of donors) {
            totalDonations += parseInt(await fundingContract.methods.getProjectDonationAmount(i, donor).call());
        }

        const card = `
            <div class="col">
                <div class="card shadow-sm">
                    <h2 class="projectTitle">${i}- ${project.title}</h2>
                    <div class="card-body">
                        <p class="card-text textProject">${project.description}</p>
                        <div class="d-flex justify-content-between align-items-center">
                            <div class="btn-group">
                                <button class="btn btn-success" type="button" onclick="donateToProject(${i})">
                                    Donate
                                </button>
                                <button class="btn btn-primary" type="button" onclick="listDonors(${i})">
                                    List of donors
                                </button>
                            </div>
                            <small class="text-body-secondary">${web3.utils.fromWei(totalDonations.toString(), 'ether')} ETH</small>
                        </div>
                    </div>
                </div>
            </div>
        `;
        container.innerHTML += card;
    }
};

const getMyAddress = async () => {
    return (await window.ethereum.request({ method: "eth_accounts" }))[0];
};

document.getElementById("createProjectBtn").addEventListener("click", async () => {
    const title = document.getElementById("projectTitle").value;
    const description = document.getElementById("projectDescription").value;
    await fundingContract.methods.createProject(title, description).send({ from: await getMyAddress() });
    await loadProjects();
});

window.donateToProject = async (projectId) => {
    const amount = prompt("Donnez la somme en ETH pour ce projet");
    if (amount) {
        await fundingContract.methods.donateToProject(projectId).send({
            from: await getMyAddress(),
            value: web3.utils.toWei(amount, "ether")
        });
        await loadProjects();
    }
};

window.listDonors = async (projectId) => {
    const donors = await fundingContract.methods.getProjectDonors(projectId).call();
    const donorDetails = await Promise.all(donors.map(async (donor, index) => {
        const donationAmount = await fundingContract.methods.getProjectDonationAmount(projectId, donor).call();
        return `${index + 1}- ${donor} : ${web3.utils.fromWei(donationAmount, 'ether')} ETH`;
    }));
    alert(donorDetails.join('\n'));
};

main();
