# Secrets Manager Rotation Lambda

This directory holds the placeholder for the rotation Lambda used by the `aws_secretsmanager_secret_rotation` resource in the `secrets-manager` module. The Terraform configuration expects a packaged artifact at `modules/secrets-manager/lambda/rotation.zip` and a handler named `index.handler`.

The Lambda should implement a standard Secrets Manager rotation function to perform the following:
- `createSecret`: Generate a new password/credential and store it as the `AWSPENDING` version of the secret.
- `setSecret`: Apply the pending credentials to the target service (e.g., update the database user password).
- `testSecret`: Verify the pending credentials can authenticate to the service.
- `finishSecret`: Promote `AWSPENDING` to `AWSCURRENT`.

A minimal Python implementation outline:

```
index.py
def handler(event, context):
    # event["Step"] is one of: "createSecret", "setSecret", "testSecret", "finishSecret"
    step = event.get("Step")
    if step == "createSecret":
        # 1. Generate new credentials
        # 2. PutSecretValue with VersionStage="AWSPENDING"
        pass
    elif step == "setSecret":
        # 1. Apply the pending credentials to the DB (e.g., change user password)
        pass
    elif step == "testSecret":
        # 1. Attempt connection/authentication with pending credentials
        pass
    elif step == "finishSecret":
        # 1. UpdateSecretVersionStage to promote AWSPENDING => AWSCURRENT
        pass
    else:
        raise ValueError(f"Unknown rotation step: {step}")
```

The Terraform module configures environment variables and IAM permissions to enable:
- Secrets Manager operations: `DescribeSecret`, `GetSecretValue`, `PutSecretValue`, `UpdateSecretVersionStage` for the specific secret.
- KMS data plane: `GenerateDataKey`, `Encrypt`, `Decrypt` for the configured CMK.
- CloudWatch Logs write-access for diagnostics.

## Expected Files

- `index.py`: Rotation handler implementation with entrypoint `handler`.
- `requirements.txt` (optional): Python dependencies if needed (keep it minimal).
- `rotation.zip`: Deployment artifact containing `index.py` (and dependencies, if any).

The repository `.gitignore` already excludes `*.zip` and `modules/secrets-manager/lambda/*.zip`.

## Packaging Instructions (Python)

From within this directory:

- Basic packaging (no dependencies):
  - `zip -j rotation.zip index.py`

- Packaging with dependencies (example using a temporary `package` directory):
  - `rm -rf package && mkdir package`
  - `pip install -r requirements.txt -t package`
  - `cp index.py package/`
  - `(cd package && zip -r ../rotation.zip .)`

Ensure the final zip contains `index.py` at the root and the handler is `index.handler`.

## Handler and Runtime

- Runtime configured in Terraform: `python3.11`
- Handler configured in Terraform: `index.handler`

If you change the file name or entrypoint:
- Update the `handler` in the Terraform resource `aws_lambda_function.rotation`.
- Rebuild `rotation.zip` accordingly.

## Rotation Logic Considerations

- Generate credentials with sufficient entropy and compliance (length, charset).
- Use Secrets Manager version stages to manage lifecycle:
  - `AWSCURRENT` for active credentials.
  - `AWSPENDING` during rotation.
- Apply credentials atomically and test connectivity before promoting the stage.
- Log meaningful events to CloudWatch Logs for observability.
- Avoid storing plaintext credentials locally; rely on the managed secret and KMS encryption.

## Validation and Testing

- Trigger rotation manually via Secrets Manager console or CLI to validate the flow.
- Confirm:
  - Secret has `AWSCURRENT` and `AWSPENDING` stages during rotation.
  - RDS authentication works with the promoted credentials post-rotation.
  - CloudWatch Logs contain diagnostic entries from each step.
