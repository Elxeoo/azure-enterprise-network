import os
import json
from azure.storage.blob import BlobServiceClient
from llama_cpp import Llama

# --- 1. SETTINGS ---
# SECURITY RULE: Never hardcode connection strings. Fetch from environment.
CONNECTION_STRING = os.environ.get("AZURE_STORAGE_CONNECTION_STRING", "YOUR_CONNECTION_STRING_HERE")
CONTAINER_NAME = "ai-input-data"

blob_service_client = BlobServiceClient.from_connection_string(CONNECTION_STRING)
container_client = blob_service_client.get_container_client(CONTAINER_NAME)
print("[1/5] Connected to Storage Account.")

# --- 2. GENERATE MOCK LOG AND WRITE TO STORAGE ---
raw_audit = {
    "event_id": "SEC-991",
    "description": "Multiple failed SSH login attempts from an unknown external IP address targeting the database server. Firewall dropped the packets.",
    "severity": "High"
}
container_client.upload_blob(name="raw_audit.json", data=json.dumps(raw_audit), overwrite=True)
print("[2/5] Raw security log successfully written to Storage.")

# --- 3. LOAD AI MODEL ---
print("[3/5] Loading AI Model (Qwen 0.5B) into local RAM and CPU... (Please wait)")
llm = Llama(
    model_path="/home/azureuser/ai_package/qwen1_5-0_5b-chat-q4_k_m.gguf",
    n_ctx=256,
    n_threads=2, # Utilize the 2 vCPUs on the D2s_v5 instance at full capacity
    verbose=False
)

# --- 4. READ FROM STORAGE AND SEND TO AI ---
print("[4/5] Reading log from Storage and sending to AI as prompt...")
downloaded_blob = container_client.get_blob_client("raw_audit.json").download_blob().readall()
audit_log = json.loads(downloaded_blob)

prompt = f"""<|im_start|>system
You are an expert cybersecurity analyst. Read the audit log and write a 2 sentence risk summary.<|im_end|>
<|im_start|>user
Log: {audit_log['description']}
Severity: {audit_log['severity']}<|im_end|>
<|im_start|>assistant
"""

print("\nAI IS THINKING...\n")
response = llm(prompt, max_tokens=64, stop=["<|im_end|>"], echo=False)
ai_summary = response['choices'][0]['text'].strip()

print(f"--- AI ANALYSIS ---\n{ai_summary}\n------------------\n")

# --- 5. SAVE RESULT TO STORAGE ---
output_data = {
    "event_id": audit_log["event_id"],
    "ai_risk_summary": ai_summary,
    "processed_by": "Air-Gapped Edge AI"
}
container_client.upload_blob(name="ai_analysis_report.json", data=json.dumps(output_data), overwrite=True)
print("[5/5] AI Analysis report successfully saved to Storage via Private Endpoint. MISSION ACCOMPLISHED!")
