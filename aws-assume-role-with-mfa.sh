#!/usr/bin/env bash

# Env vars:
#
# Either:
#
# PROFILE
# Named profile from your aws config file
#
# OR:
#
# ROLE_ARN
# ARN of the role you want to assume.
#
# MFA_SERIAL_NUMBER
# ARN of the MFA device you want to authenticate with
#
# ROLE_SESSION_NAME
# A unique name for the session
#
# Optional environment variables:
# DEBUG
# If not empty, will output each command before executing (i.e. set -x)

set -e
if [ -z "$DEBUG" ]
then
  true
else
  set -x
fi


username=$(aws iam get-user | jq -r '.User .UserName')
mfa_arn=$(aws iam list-mfa-devices --user-name $username | jq -r '.MFADevices[0] .SerialNumber')

function set_env_vars_from_json {
  json=$1
  export AWS_ACCESS_KEY_ID=$(echo $json | jq -r '.Credentials .AccessKeyId')
  export AWS_SECRET_ACCESS_KEY=$(echo $json | jq -r '.Credentials .SecretAccessKey')
  export AWS_SESSION_TOKEN=$(echo $json | jq -r '.Credentials .SessionToken')
}

function get_profile_details_from_input {
  if [ -z "$ROLE_ARN" ]; then
    echo "ARN of the role you want to assume:"
    read ROLE_ARN
  fi

  if [ -z "$ROLE_SESSION_NAME" ]; then
    echo "A unique name for the session using the role:"
    read ROLE_SESSION_NAME
  fi

  if [ -z "$MFA_SERIAL_NUMBER" ]; then
    echo "ARN of your MFA device:"
    read MFA_SERIAL_NUMBER
  fi
}

function get_profile_details_from_config {
  ROLE_ARN=$(aws configure get role_arn --profile ${PROFILE})
  ROLE_SESSION_NAME="${PROFILE}-session"
  # the MFA ARN might not be defined in the role profile, but in the
  # source profile instead, in which case the aws configure call will
  # return a non-zero exit code, triggering an immediate exit
  MFA_SERIAL_NUMBER=$(aws configure get mfa_arn --profile ${PROFILE}) || true
  if [ -z "${MFA_SERIAL_NUMBER}" ]; then
    SOURCE_PROFILE=$(aws configure get source_profile --profile ${PROFILE})
    MFA_SERIAL_NUMBER=$(aws configure get mfa_arn --profile ${SOURCE_PROFILE})
  fi
}

temp_credentials=$(aws sts get-session-token)
set_env_vars_from_json "$temp_credentials"

if [ -z "${PROFILE}" ]; then
  get_profile_details_from_input
else
  echo "Getting details for profile ${PROFILE}"
  get_profile_details_from_config
fi

if [ -z "${TOKEN_CODE}" ]; then
  echo ""
  echo "Please enter a valid MFA token for device ${MFA_SERIAL_NUMBER}:"
  read TOKEN_CODE
fi

role_json=$(aws sts assume-role --role-arn ${ROLE_ARN} \
                    --role-session-name ${ROLE_SESSION_NAME} \
                    --serial-number ${MFA_SERIAL_NUMBER} \
                    --token-code ${TOKEN_CODE})
set_env_vars_from_json "$role_json"
identity=$(aws sts get-caller-identity | jq -r '.Arn')
echo "====================================================================="
echo "You are now entering a subshell as ${identity}"
echo "type 'exit' to exit this subshell and return to your previous AWS identity"
export PS1="${PS1}bash-with-role> "
bash
