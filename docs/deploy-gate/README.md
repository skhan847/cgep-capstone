# Deploy gate (Moto)

Result: PASSED. handler returned {"submission_id": "...", "status": "received"}
and the record is in DynamoDB (see dynamodb-scan.json).

## Gap: API Gateway -> Lambda path not exercised
In a real AWS account, calling api_url would send the form through API Gateway
to Lambda, which runs handler.py. Moto needs Docker to run Lambda code, and
Docker is not installed because of limited disk space. So instead we ran the
same handler.py with local Python, pointed at Moto's DynamoDB and S3.

This proves the app logic works and writes to the table Terraform built.
It does NOT prove the API Gateway -> Lambda path (routing, invoke permission,
Lambda runtime). Closing this gap needs a real AWS sandbox.
