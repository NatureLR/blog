layout: draft
title: K8s动态准入控制
author: Nature丿灵然
tags:
  - k8s
categories:
  - 开发
date: 2021-06-17 11:28:00
---
准入控制是k8s中用来提供安全控制的一个控制器，而动态控制则是用户定制的安全策略

<!--more-->

#### 种类

> 动态准入控制分为两种，分别为Mutating，Validating

##### Mutating

Mutating主要为修改性质的，在api调用完成之后k8s会根据`ValidatingWebhookConfiguration`中的条件发送给配置的webhook服务，webhook服务根据业务逻辑进行修改，比如说大名鼎鼎的istio的Sidecar注入就是于此

##### Validating

Validating主要为验证性质的，主要看是不是符合条件集群要求，比方说为了高可用不允许设置副本数为1的类型为deployment的请求

#### 架构

> 下图所显的是api请求的流程
![upload successful](/images/pasted-24.png)

#### 编写webhook

##### 创建证书

> 创建证书的的程序很多比较出名的是`openssl`，这里我们使用rancher提供的一个自动生成证书的脚本

###### 1. 将下面的脚本保存为`create_self-signed-cert.sh`

```shell
#!/bin/bash -e

help ()
{
    echo  ' ================================================================ '
    echo  ' --ssl-domain: 生成ssl证书需要的主域名，如不指定则默认为www.rancher.local，如果是ip访问服务，则可忽略；'
    echo  ' --ssl-trusted-ip: 一般ssl证书只信任域名的访问请求，有时候需要使用ip去访问server，那么需要给ssl证书添加扩展IP，多个IP用逗号隔开；'
    echo  ' --ssl-trusted-domain: 如果想多个域名访问，则添加扩展域名（SSL_TRUSTED_DOMAIN）,多个扩展域名用逗号隔开；'
    echo  ' --ssl-size: ssl加密位数，默认2048；'
    echo  ' --ssl-cn: 国家代码(2个字母的代号),默认CN;'
    echo  ' 使用示例:'
    echo  ' ./create_self-signed-cert.sh --ssl-domain=www.test.com --ssl-trusted-domain=www.test2.com \ '
    echo  ' --ssl-trusted-ip=1.1.1.1,2.2.2.2,3.3.3.3 --ssl-size=2048 --ssl-date=3650'
    echo  ' ================================================================'
}

case "$1" in
    -h|--help) help; exit;;
esac

if [[ $1 == '' ]];then
    help;
    exit;
fi

CMDOPTS="$*"
for OPTS in $CMDOPTS;
do
    key=$(echo ${OPTS} | awk -F"=" '{print $1}' )
    value=$(echo ${OPTS} | awk -F"=" '{print $2}' )
    case "$key" in
        --ssl-domain) SSL_DOMAIN=$value ;;
        --ssl-trusted-ip) SSL_TRUSTED_IP=$value ;;
        --ssl-trusted-domain) SSL_TRUSTED_DOMAIN=$value ;;
        --ssl-size) SSL_SIZE=$value ;;
        --ssl-date) SSL_DATE=$value ;;
        --ca-date) CA_DATE=$value ;;
        --ssl-cn) CN=$value ;;
    esac
done

# CA相关配置
CA_DATE=${CA_DATE:-3650}
CA_KEY=${CA_KEY:-cakey.pem}
CA_CERT=${CA_CERT:-cacerts.pem}
CA_DOMAIN=cattle-ca

# ssl相关配置
SSL_CONFIG=${SSL_CONFIG:-$PWD/openssl.cnf}
SSL_DOMAIN=${SSL_DOMAIN:-'www.rancher.local'}
SSL_DATE=${SSL_DATE:-3650}
SSL_SIZE=${SSL_SIZE:-2048}

## 国家代码(2个字母的代号),默认CN;
CN=${CN:-CN}

SSL_KEY=$SSL_DOMAIN.key
SSL_CSR=$SSL_DOMAIN.csr
SSL_CERT=$SSL_DOMAIN.crt

echo -e "\033[32m ---------------------------- \033[0m"
echo -e "\033[32m       | 生成 SSL Cert |       \033[0m"
echo -e "\033[32m ---------------------------- \033[0m"

if [[ -e ./${CA_KEY} ]]; then
    echo -e "\033[32m ====> 1. 发现已存在CA私钥，备份"${CA_KEY}"为"${CA_KEY}"-bak，然后重新创建 \033[0m"
    mv ${CA_KEY} "${CA_KEY}"-bak
    openssl genrsa -out ${CA_KEY} ${SSL_SIZE}
else
    echo -e "\033[32m ====> 1. 生成新的CA私钥 ${CA_KEY} \033[0m"
    openssl genrsa -out ${CA_KEY} ${SSL_SIZE}
fi

if [[ -e ./${CA_CERT} ]]; then
    echo -e "\033[32m ====> 2. 发现已存在CA证书，先备份"${CA_CERT}"为"${CA_CERT}"-bak，然后重新创建 \033[0m"
    mv ${CA_CERT} "${CA_CERT}"-bak
    openssl req -x509 -sha256 -new -nodes -key ${CA_KEY} -days ${CA_DATE} -out ${CA_CERT} -subj "/C=${CN}/CN=${CA_DOMAIN}"
else
    echo -e "\033[32m ====> 2. 生成新的CA证书 ${CA_CERT} \033[0m"
    openssl req -x509 -sha256 -new -nodes -key ${CA_KEY} -days ${CA_DATE} -out ${CA_CERT} -subj "/C=${CN}/CN=${CA_DOMAIN}"
fi

echo -e "\033[32m ====> 3. 生成Openssl配置文件 ${SSL_CONFIG} \033[0m"
cat > ${SSL_CONFIG} <<EOM
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth, serverAuth
EOM

if [[ -n ${SSL_TRUSTED_IP} || -n ${SSL_TRUSTED_DOMAIN} ]]; then
    cat >> ${SSL_CONFIG} <<EOM
subjectAltName = @alt_names
[alt_names]
EOM
    IFS=","
    dns=(${SSL_TRUSTED_DOMAIN})
    dns+=(${SSL_DOMAIN})
    for i in "${!dns[@]}"; do
      echo DNS.$((i+1)) = ${dns[$i]} >> ${SSL_CONFIG}
    done

    if [[ -n ${SSL_TRUSTED_IP} ]]; then
        ip=(${SSL_TRUSTED_IP})
        for i in "${!ip[@]}"; do
          echo IP.$((i+1)) = ${ip[$i]} >> ${SSL_CONFIG}
        done
    fi
fi

echo -e "\033[32m ====> 4. 生成服务SSL KEY ${SSL_KEY} \033[0m"
openssl genrsa -out ${SSL_KEY} ${SSL_SIZE}

echo -e "\033[32m ====> 5. 生成服务SSL CSR ${SSL_CSR} \033[0m"
openssl req -sha256 -new -key ${SSL_KEY} -out ${SSL_CSR} -subj "/C=${CN}/CN=${SSL_DOMAIN}" -config ${SSL_CONFIG}

echo -e "\033[32m ====> 6. 生成服务SSL CERT ${SSL_CERT} \033[0m"
openssl x509 -sha256 -req -in ${SSL_CSR} -CA ${CA_CERT} \
    -CAkey ${CA_KEY} -CAcreateserial -out ${SSL_CERT} \
    -days ${SSL_DATE} -extensions v3_req \
    -extfile ${SSL_CONFIG}

echo -e "\033[32m ====> 7. 证书制作完成 \033[0m"
echo
echo -e "\033[32m ====> 8. 以YAML格式输出结果 \033[0m"
echo "----------------------------------------------------------"
echo "ca_key: |"
cat $CA_KEY | sed 's/^/  /'
echo
echo "ca_cert: |"
cat $CA_CERT | sed 's/^/  /'
echo
echo "ssl_key: |"
cat $SSL_KEY | sed 's/^/  /'
echo
echo "ssl_csr: |"
cat $SSL_CSR | sed 's/^/  /'
echo
echo "ssl_cert: |"
cat $SSL_CERT | sed 's/^/  /'
echo

echo -e "\033[32m ====> 9. 附加CA证书到Cert文件 \033[0m"
cat ${CA_CERT} >> ${SSL_CERT}
echo "ssl_cert: |"
cat $SSL_CERT | sed 's/^/  /'
echo

echo -e "\033[32m ====> 10. 重命名服务证书 \033[0m"
echo "cp ${SSL_DOMAIN}.key tls.key"
cp ${SSL_DOMAIN}.key tls.key
echo "cp ${SSL_DOMAIN}.crt tls.crt"
cp ${SSL_DOMAIN}.crt tls.crt

```

###### 2. 然后执行下面的命令

```shell
./create_self-signed-cert.sh --ssl-domain=admission-example.admission-example.svc.cluster.local  --ssl-trusted-domain=admission-example,admission-example.admission-example.svc -ssl-trusted-ip=127.0.0.1
```

###### 3. 会在目录里生成一套证书和秘钥

- .key的为秘钥
- .crt为域名的证书
- csr文件为证书申请文件
- ca开头的为根证书和秘钥

##### 编写yaml文件

> 编写MutatingWebhookConfiguration和ValidatingWebhookConfiguration

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: MutatingWebhookConfiguration
metadata:
  name: mutating-example
  labels:
    app: admission-example
webhooks:
  - name: admission-example.naturelr.cc
    clientConfig:
      service:
        name: admission-example
        namespace: admission-example
        path: "/mutate"
        port: 8080
      # 证书进行base64编码
      caBundle: {{CA}}
    rules:
      - operations: [ "CREATE" ]
        apiGroups: ["apps", ""]
        apiVersions: ["v1"]
        resources: ["deployments","services"]
    admissionReviewVersions: ["v1", "v1beta1"]
    sideEffects: None
    # 只有ns上拥有admission-webhook-example: enabled才生效
    namespaceSelector:
      matchLabels:
        admission-webhook-example: enabled
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: validation-example
  labels:
    app: admission-example
webhooks:
  - name: admission-example.naturelr.cc
    clientConfig:
      service:
        name: admission-example
        namespace: admission-example
        path: "/validate"
        port: 8080
      caBundle: {{CA}}
    rules:
      - operations: [ "CREATE" ]
        apiGroups: ["apps", ""]
        apiVersions: ["v1"]
        resources: ["deployments","services"]
    admissionReviewVersions: ["v1", "v1beta1"]
    sideEffects: None
    namespaceSelector:
      matchLabels:
        admission-webhook-example: enabled
```

##### 开发webhook

> 开发上面定义的两个接口validate，mutate

监听的端口和上面配置的端口一直，且使用创建的证书

```go
...
  http.HandleFunc("/validate", validate)
  http.HandleFunc("/mutate", mutate)
  http.HandleFunc("/ping", func(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintln(w, "pong")
  })

  svr := http.Server{
    Addr:         ":8080",
    ReadTimeout:  time.Minute,
    WriteTimeout: time.Minute,
  }
  go func() {
    if *key == "" || *cert == "" {
      fmt.Println("http服务启动成功")
      if err := svr.ListenAndServe(); err != nil {
        log.Fatalln(err)
      }
    }
    fmt.Println("https服务启动成功")
    if err := svr.ListenAndServeTLS(*cert, *key); err != nil {
      log.Fatalln(err)
  }()  
    }
```

> 实现mutate的部分，我们需要给满足条件的deployment和service添加一个名为`admission-example.naturelr.cc/status": "test"`的注解\
> 这里和使用kubectl操作上很像只不过由代码返回给k8s

```go
func mutate(w http.ResponseWriter, r *http.Request) {
  // 请求结构体
  qar := admissionv1.AdmissionReview{}
  _, _, err := serializer.NewCodecFactory(runtime.NewScheme()).UniversalDeserializer().Decode(body, nil, &qar)
  checkErr(err)  
  type patchOperation struct {
    Op    string      `json:"op"`
    Path  string      `json:"path"`
    Value interface{} `json:"value,omitempty"`
  }  
  p := patchOperation{
    Op:    "add",
    Path:  "/metadata/annotations",
    Value: map[string]string{"admission-example.naturelr.cc/status": "test"},
  }
  patch, err := json.Marshal([]patchOperation{p})
  checkErr(err)

  // 返回给k8s的消息
  are := &admissionv1.AdmissionReview{
    TypeMeta: apimetav1.TypeMeta{
      APIVersion: qar.APIVersion,
      Kind:       qar.Kind,
    },
    Response: &admissionv1.AdmissionResponse{
      Allowed: true,
      Patch:   patch,
      PatchType: func() *admissionv1.PatchType {
        pt := admissionv1.PatchTypeJSONPatch
        return &pt
      }(),
      UID: qar.Request.UID,
    },
  }

  resp, err := json.Marshal(are)
  checkErr(err)
  fmt.Println("响应:", string(resp))
  w.WriteHeader(200)
  w.Write(resp)
}
```

> validate中主要验证service和deployment中标签是否有admission字段如果就没有则拒绝访问

```go
func validate(w http.ResponseWriter, r *http.Request) {
    // 请求结构体
  qar := admissionv1.AdmissionReview{}
  _, _, err := serializer.NewCodecFactory(runtime.NewScheme()).UniversalDeserializer().Decode(body, nil, &qar)
  checkErr(err
  // 处理逻辑 从请求的结构体判断是是否满足条件
  var  availableLabels map[string]string
  
  requiredLabels := "admission"
  var errMsg error
  switch qar.Request.Kind.Kind {
  case "Deployment":
    var deploy appsv1.Deployment
    if err := json.Unmarshal(qar.Request.Object.Raw, &deploy); err != nil {
      log.Println("无法解析格式:", err)
      errMsg = err
    }
    availableLabels = deploy.Labels
  case "Service":
    var service corev1.Service
    if err := json.Unmarshal(qar.Request.Object.Raw, &service); err != nil {
      log.Println("无法解析格式:", err)
      errMsg = err
    }
    availableLabels = service.Labels
  default:
    msg := fmt.Sprintln("不能处理的类型：", qar.Request.Kind.Kind)
    log.Println(msg)
    errMsg = errors.New(msg)
  }

  var status *apimetav1.Status
  var allowed bool
  if _, ok := availableLabels[requiredLabels]; !ok || errMsg != nil {
    msg := "不符合条件"
    if err != nil {
        msg = fmt.Sprintln(errMsg)
    }
  }
  status = &apimetav1.Status{
      Message: msg,
      Reason:  apimetav1.StatusReason(msg),
      Code:    304,
    }
    allowed = false
  } else {
    Message: "通过",
    status = &apimetav1.Status{
     Reason:  "通过",
     Code:    200,
    }
    allowed = true
  }

  // 返回给k8s的消息
  are := &admissionv1.AdmissionReview{
    TypeMeta: apimetav1.TypeMeta{
      APIVersion: qar.APIVersion,
      Kind:       qar.Kind,
    },
    Response: &admissionv1.AdmissionResponse{
      Allowed: allowed,
      Result:  status,
      UID:     qar.Request.UID,
    },
  }

  resp, err := json.Marshal(are)
  checkErr(err)
  fmt.Println("响应:", string(resp))
  w.WriteHeader(200)
  w.Write(resp)
```

完整项目在<https://github.com/NatureLR/admission-example>

##### 测试验证

- 在打了`admission-webhook-example: enabled`标签下的ns中随便创建一个应用会发现被拒绝
- 在给deployment打上了设定的标签之后就可以创建了，且deployment多了一个注解

#### 参考资料

<https://kubernetes.io/zh/docs/reference/access-authn-authz/admission-controllers/>
<https://kubernetes.io/zh/docs/reference/access-authn-authz/extensible-admission-controllers/>
