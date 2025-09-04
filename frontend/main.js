document.getElementById("scan-btn").addEventListener("click", async () => {
    const API = "https://xmdr0osr37.execute-api.us-east-1.amazonaws.com";

    const resultDiv = document.getElementById("result");
    resultDiv.textContent = "Running scan...";

    try {
        const response = await fetch("https://xmdr0osr37.execute-api.us-east-1.amazonaws.com/scan"); // Replace with real URL
        if (!response.ok) {
            throw new Error(`HTTP error! Status: ${response.status}`);
        }
        const data = await response.json();
        resultDiv.textContent = data.message || "Scan complete!";
    } catch (error) {
        console.error(error);
        resultDiv.textContent = "Error: Could not start scan.";
    }
});

document.getElementById("remediate-s3").addEventListener("click", async () => {
  const bucketName = prompt("Enter bucket name:");
  const res = await fetch(`${API}/remediate/s3/${bucketName}`, { method: "POST" });
  const data = await res.json();
  alert(JSON.stringify(data, null, 2));
});

document.getElementById("remediate-sg").addEventListener("click", async () => {
  const sgId = prompt("Enter Security Group ID:");
  const res = await fetch(`${API}/remediate/sg/${sgId}`, { method: "POST" });
  const data = await res.json();
  alert(JSON.stringify(data, null, 2));
});

document.getElementById("remediate-rds").addEventListener("click", async () => {
  const dbId = prompt("Enter RDS instance identifier:");
  const res = await fetch(`${API}/remediate/rds/${dbId}`, { method: "POST" });
  const data = await res.json();
  alert(JSON.stringify(data, null, 2));
});


document.getElementById("scan-btn").onclick = async () => {
  const res = await fetch(`${API}/scan`);
  const data = await res.json();
  document.getElementById("results").innerText = JSON.stringify(data, null, 2);
};

document.getElementById("remediate-s3-btn").onclick = async () => {
  const bucket = document.getElementById("s3-bucket").value;
  const res = await fetch(`${API}/remediate/s3/${bucket}`, { method: "POST" });
  const data = await res.json();
  document.getElementById("results").innerText = JSON.stringify(data, null, 2);
};

document.getElementById("remediate-sg-btn").onclick = async () => {
  const sg = document.getElementById("sg-id").value;
  const res = await fetch(`${API}/remediate/sg/${sg}`, { method: "POST" });
  const data = await res.json();
  document.getElementById("results").innerText = JSON.stringify(data, null, 2);
};

document.getElementById("remediate-rds-btn").onclick = async () => {
  const rds = document.getElementById("rds-id").value;
  const res = await fetch(`${API}/remediate/rds/${rds}`, { method: "POST" });
  const data = await res.json();
  document.getElementById("results").innerText = JSON.stringify(data, null, 2);
};
