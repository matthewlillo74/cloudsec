# api.py
from fastapi import FastAPI
from scanner import (
    check_public_s3_buckets, check_security_groups, check_iam_mfa,
    check_cloudtrail, check_public_rds
)
from remediator import fix_public_s3, fix_open_sg, fix_public_rds
from mangum import Mangum
import os
import boto3
import time

app = FastAPI(title="Cloud Security Platform")

@app.get("/scan")
def scan():
    results = {
        "public_s3": check_public_s3_buckets(),
        "open_sg": check_security_groups(),
        "iam_users_no_mfa": check_iam_mfa(),
        "cloudtrail_issues": check_cloudtrail(),
        "rds_public": check_public_rds(),
    }
    # Optional: persist scan in DynamoDB
    table_name = os.getenv("SCAN_TABLE")
    if table_name:
        ddb = boto3.resource("dynamodb").Table(table_name)
        ddb.put_item(Item={
            "pk": f"scan#{int(time.time())}",
            "type": "scan",
            "results": results
        })
    return results

@app.post("/remediate/s3/{bucket_name}")
def remediate_s3(bucket_name: str):
    fix_public_s3(bucket_name)
    _log_action("remediate_s3", bucket_name)
    return {"status": "S3 bucket fixed", "bucket": bucket_name}

@app.post("/remediate/sg/{sg_id}")
def remediate_sg(sg_id: str):
    fix_open_sg(sg_id)
    _log_action("remediate_sg", sg_id)
    return {"status": "Security group fixed", "sg": sg_id}

@app.post("/remediate/rds/{db_identifier}")
def remediate_rds(db_identifier: str):
    fix_public_rds(db_identifier)
    _log_action("remediate_rds", db_identifier)
    return {"status": "RDS instance fixed", "db_instance": db_identifier}

def _log_action(action: str, target: str):
    table_name = os.getenv("SCAN_TABLE")
    if table_name:
        ddb = boto3.resource("dynamodb").Table(table_name)
        ddb.put_item(Item={
            "pk": f"action#{int(time.time())}",
            "type": "action",
            "action": action,
            "target": target
        })

# 👇 Lambda entrypoint
handler = Mangum(app)
