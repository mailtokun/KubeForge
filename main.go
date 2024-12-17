package main

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

func sha256hex(s string) string {
	b := sha256.Sum256([]byte(s))
	return hex.EncodeToString(b[:])
}

func hmacsha256(s, key string) string {
	hashed := hmac.New(sha256.New, []byte(key))
	hashed.Write([]byte(s))
	return string(hashed.Sum(nil))
}

func main() {
	service := "cvm"
	version := "2017-03-12"
	action := "RunInstances"
	region := "ap-beijing"
	// 实例化一个认证对象，入参需要传入腾讯云账户 SecretId 和 SecretKey，此处还需注意密钥对的保密
	// 代码泄露可能会导致 SecretId 和 SecretKey 泄露，并威胁账号下所有资源的安全性。以下代码示例仅供参考，建议采用更安全的方式来使用密钥，请参见：https://cloud.tencent.com/document/product/1278/85305
	// 密钥可前往官网控制台 https://console.cloud.tencent.com/cam/capi 进行获取
	secretId := os.Getenv("Tencent_vm_SecretId")
	secretKey := os.Getenv("Tencent_vm_SecretKey")
	token := ""
	host := "cvm.tencentcloudapi.com"
	algorithm := "TC3-HMAC-SHA256"
	var timestamp = time.Now().Unix()

	// ************* 步骤 1：拼接规范请求串 *************
	httpRequestMethod := "POST"
	canonicalURI := "/"
	canonicalQueryString := ""
	contentType := "application/json; charset=utf-8"
	canonicalHeaders := fmt.Sprintf("content-type:%s\nhost:%s\nx-tc-action:%s\n",
		contentType, host, strings.ToLower(action))
	signedHeaders := "content-type;host;x-tc-action"
	payload := `{
  "InstanceChargeType": "SPOTPAID",
  "Placement": {
    "Zone": "ap-beijing-6"
  },
  "ImageId": "img-mmytdhbn",
  "SystemDisk": {
    "DiskType": "CLOUD_BSSD",
    "DiskSize": 20
  },
  "InternetAccessible": {
    "InternetChargeType": "TRAFFIC_POSTPAID_BY_HOUR",
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
  "CpuTopology": {
    "CoreCount": 2,
	"ThreadPerCore": 2
  }
}`
	hashedRequestPayload := sha256hex(payload)
	canonicalRequest := fmt.Sprintf("%s\n%s\n%s\n%s\n%s\n%s",
		httpRequestMethod,
		canonicalURI,
		canonicalQueryString,
		canonicalHeaders,
		signedHeaders,
		hashedRequestPayload)
	// log.Println(canonicalRequest)

	// ************* 步骤 2：拼接待签名字符串 *************
	date := time.Unix(timestamp, 0).UTC().Format("2006-01-02")
	credentialScope := fmt.Sprintf("%s/%s/tc3_request", date, service)
	hashedCanonicalRequest := sha256hex(canonicalRequest)
	string2sign := fmt.Sprintf("%s\n%d\n%s\n%s",
		algorithm,
		timestamp,
		credentialScope,
		hashedCanonicalRequest)
	// log.Println(string2sign)

	// ************* 步骤 3：计算签名 *************
	secretDate := hmacsha256(date, "TC3"+secretKey)
	secretService := hmacsha256(service, secretDate)
	secretSigning := hmacsha256("tc3_request", secretService)
	signature := hex.EncodeToString([]byte(hmacsha256(string2sign, secretSigning)))
	// log.Println(signature)

	// ************* 步骤 4：拼接 Authorization *************
	authorization := fmt.Sprintf("%s Credential=%s/%s, SignedHeaders=%s, Signature=%s",
		algorithm,
		secretId,
		credentialScope,
		signedHeaders,
		signature)
	// log.Println(authorization)

	// ************* 步骤 5：构造并发起请求 *************
	url := "https://" + host
	httpRequest, _ := http.NewRequest("POST", url, strings.NewReader(payload))
	httpRequest.Header = map[string][]string{
		"Host":           {host},
		"X-TC-Action":    {action},
		"X-TC-Version":   {version},
		"X-TC-Timestamp": {strconv.FormatInt(timestamp, 10)},
		"Content-Type":   {contentType},
		"Authorization":  {authorization},
	}
	if region != "" {
		httpRequest.Header["X-TC-Region"] = []string{region}
	}
	if token != "" {
		httpRequest.Header["X-TC-Token"] = []string{token}
	}
	httpClient := http.Client{}
	fmt.Println("发起创建虚拟机的请求...")
	resp, err := httpClient.Do(httpRequest)
	if err != nil {
		log.Println(err)
		return
	}
	defer resp.Body.Close()
	body := &bytes.Buffer{}
	_, err = body.ReadFrom(resp.Body)
	if err != nil {
		log.Println(err)
		return
	}
	log.Println(body.String())

	fmt.Println("\nDONE!!!.")
}
