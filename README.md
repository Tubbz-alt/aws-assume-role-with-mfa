# aws-assume-role-with-mfa
Wrapper script to simplify the process of assuming an AWS IAM role with MFA

# Usage

There are two ways to use this script, either by pointing to an AWS profile in your config file, or as a series of interactive prompts.

In either case, you must have valid credentials (in your environment or AWS profile) for an IAM user who has permission to assume the target role.

## With an AWS Profile

Assumptions:
1. You have a named AWS profile in your config / credentials file
2. That profile defines role_arn, role_session_name, and either mfa_arn or a source_profile referring to another profile which defines mfa_arn

```bash
PROFILE=(profile name) aws-assume-role-with-mfa.sh
```
## As a series of prompts

```bash
aws-assume-role-with-mfa.sh
```

In this mode, you MAY (but are not required to) provide any of the following environment variables:

*ROLE_ARN* - the ARN of the role you want to assume
*ROLE_SESSION_NAME* - some arbitrary unique name for the session
*MFA_SERIAL_NUMBER* - ARN of the MFA device with which you will authenticate

The script will prompt you for any of the values above if they are not present in the environment

