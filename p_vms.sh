#!/bin/bash

# 替换为实际密钥和服务参数
secretKey=${Tencent_vm_SecretKey}
service="cvm"
algorithm="TC3-HMAC-SHA256"
date=$(date -u +"%Y-%m-%d")
timestamp=$(date +%s)
region="ap-beijing"

# 替换为你的真实 CanonicalRequest 和 HashedCanonicalRequest
canonical_request="..."
hashed_canonical_request=$(printf "$canonical_request" | openssl dgst -sha256 | awk '{print $2}')

# Credential Scope
credential_scope="$date/$service/tc3_request"

# String to Sign
string_to_sign="$algorithm\n$timestamp\n$credential_scope\n$hashed_canonical_request"

# Signature 计算步骤
secret_date=$(printf "$date" | openssl dgst -sha256 -hmac "TC3$secretKey" -binary)
secret_service=$(printf "$service" | openssl dgst -sha256 -hmac "$secret_date" -binary)
secret_signing=$(printf "tc3_request" | openssl dgst -sha256 -hmac "$secret_service" -binary)
calculated_signature=$(printf "$string_to_sign" | openssl dgst -sha256 -hmac "$secret_signing" | awk '{print $2}')

echo "Calculated Signature: $calculated_signature"

curl -X POST "https://cvm.tencentcloudapi.com" \
-H "Host: cvm.tencentcloudapi.com" \
-H "X-TC-Action: RunInstances" \
-H "X-TC-Version: 2017-03-12" \
-H "X-TC-Timestamp: $(date +%s)" \
-H "X-TC-Region: ap-beijing" \
-H "Content-Type: application/json; charset=utf-8" \
-H "Authorization: TC3-HMAC-SHA256 Credential=${Tencent_vm_SecretId}/$(date -u +%Y-%m-%d)/cvm/tc3_request, SignedHeaders=content-type;host;x-tc-action, Signature=${calculated_signature}" \
-d '{
    "InstanceChargeType": "SPOTPAID",
    "ImageId": "img-mmytdhbn",
    "SystemDisk": {
        "DiskType": "CLOUD_BSSD",
        "DiskSize": 20
    },
    "InternetAccessible": {
        "InternetChargeType": "BANDWIDTH_POSTPAID_BY_HOUR",
        "InternetMaxBandwidthOut": 1,
        "PublicIpAssigned": true
    },
    "InstanceCount": 2,
    "InstanceName": "kube_server_",
    "LoginSettings": {
        "KeyIds": [
            "skey-pek7ybir"
        ]
    },
    "HostName": "kube_server",
    "ActionTimer": {
        "TimerAction": "TerminateInstances",
        "ActionTime": "'$(date -u -d "+1 hours" +"%Y-%m-%dT%H:%M:%SZ")'"
    }
}'

