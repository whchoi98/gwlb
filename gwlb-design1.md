---
description: 'update : 2023-01-16/ 1h / "Cloudformation CLI 배포방식으로 변경"'
---

# GWLB Design 1

## 목표 구성 개요

3개의 각 워크로드 VPC (VPC01,02,03)은 Account내에 구성된 GWLB 기반의 보안 VPC를 통해서 내, 외부 트래픽을 처리하는 구성입니다. GWLB 기반의 보안 VPC는 2개의 AZ에 4개의 가상 Appliance가 로드밸런싱을 통해 처리 됩니다.

이러한 구성은 VPC Endpoint를 각 VPC에 분산하고, GWLB에 VPC Endpoint Service를 연결하는 분산형 구조입니다.

아래 그림은 목표 구성도 입니다.

#### :clapper: 아래 동영상 링크에서 구성방법을 확인 할 수 있습니다.

{% embed url="https://youtu.be/J4mXEfsWZUs" %}



![](<.gitbook/assets/image (154).png>)

## Cloudformation기반 VPC 배포

### 1.VPC yaml 파일 다운로드&#x20;

Cloud9 콘솔에서 아래 github로 부터 VPC yaml 파일을 다운로드 합니다.&#x20;

```
git clone https://github.com/whchoi98/gwlb.git

```

### 2.AWS 관리콘솔에서 VPC 배포

아래와 같이 Cloud9에서 Cloudformation을 실행합니다



AWS 관리콘솔에서 Cloudformation을 선택해서, 실행 결과를 확인해 봅니다

![](<.gitbook/assets/image (136).png>)

먼저 GWLBVPC를 실행합니다

스택 세부 정보 지정에서 , 스택이름과 VPC Parameters를 지정합니다. 대부분 기본값을 사용하면 됩니다.

* 스택이름 : GWLBVPC
* AvailabilityZone A : ap-northeast-2a
* AvailabilityZone B : ap-northeast-2b
* VPCCIDRBlock: 10.254.0.0/16
* PublicSubnetABlock: 10.254.11.0/24
* PublicSubnetBBlock: 10.254.12.0/24
* InstanceTyep: t3.small
* KeyPair : 미리 만들어 둔 keyPair를 사용합니다.

```
cd ~/environment/
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "GWLBVPC" \
  --template-file "/home/ec2-user/environment/gwlb/Case1/1.Case1-GWLBVPC.yml" \
  --parameter-overrides "KeyPair=$KeyName" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

3\~4분 후에 GWLBVPC가 완성됩니다.

AWS 관리콘솔 - VPC - 가상 프라이빗 클라우드 - 엔드포인트 서비스 를 선택합니다.

&#x20;Cloudformation을 통해서 VPC Endpoint 서비스가 이미 생성되어 있습니다. 이것을 선택하고 세부 정보를 확인합니다. VPC Endpoint Service Name을 복사해 둡니다. 뒤에서 생성할 VPC들의 Cloudformation에서 사용할 것입니다.

![](<.gitbook/assets/image (3).png>)

아래에서 처럼 AWS CLI로 VPC Endpoint Service Name을 확인하고 변수에 저장할 수도 있습니다.

```
export VPCEndpointServiceName1=$(aws ec2 describe-vpc-endpoint-services --filter "Name=service-type,Values=GatewayLoadBalancer" | jq -r '.ServiceNames[]')
echo $VPCEndpointServiceName1
echo "export VPCEndpointServiceName1=${VPCEndpointServiceName1}" | tee -a ~/.bash_profile
source ~/.bash_profile

```

VPC01,02,03 3개의 VPC를 Cloudformation에서 앞서 과정과 동일하게 생성합니다. 다운로드 받은 Yaml 파일들 중에 VPC01.yml, VPC02,yml, VPC03.yml을 생성합니다.

스택 이름을 생성하고, 환경변수에 설정한 GWLBVPC의 VPC Endpoint 서비스 이름을 사용합니다 .

&#x20;또한 나머지 파라미터들도 입력합니다. 대부분 기본값을 사용합니다.

* 스택이름 : VPC01, VPC02, VPC03
* AvailabilityZone A : ap-northeast-2a
* AvailabilityZone B : ap-northeast-2b
* VPCCIDRBlock: 10.1.0.0/16 (VPC01), 10.2.0.0/16 (VPC02), 10.3.0.0/16 (VPC03)
* PublicSubnetABlock: 10.1.11.0/24 (VPC01), 10.2.11.0/24 (VPC02), 10.3.11.0/24 (VPC03)
* PublicSubnetBBlock: 10.1.12.0/24 (VPC01), 10.2.12.0/24 (VPC02), 10.3.12.0/24 (VPC03)
* VPCEndpointServiceName : 앞서 복사해둔 GWLBVPC의 VPC endpoint service name을 입력합니다.
* PrivateToGWLB : 0.0.0.0/0 (Private Subnet이 외부로 가는 목적지에 대한 라우팅 경로 설정입니다.)
* InstanceTyep: t3.small
* KeyPair : 미 만들어 둔 keyPair를 사용합니다.&#x20;

```
cd ~/environment/
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "VPC01" \
  --template-file "/home/ec2-user/environment/gwlb/Case1/2.Case1-VPC01.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
    "VPCEndpointServiceName=$VPCEndpointServiceName1" \
  --capabilities CAPABILITY_NAMED_IAM

```

```
cd ~/environment/
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "VPC02" \
  --template-file "/home/ec2-user/environment/gwlb/Case1/2.Case1-VPC02.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
    "VPCEndpointServiceName=$VPCEndpointServiceName1" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

```
cd ~/environment/
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "VPC03" \
  --template-file "/home/ec2-user/environment/gwlb/Case1/2.Case1-VPC03.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
    "VPCEndpointServiceName=$VPCEndpointServiceName1" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

아래와 같이 VPC가 모두 정상적으로 설정되었는지 확인해 봅니다.

AWS 관리콘솔 - VPC

![](<.gitbook/assets/image (85).png>)

## GWLB 구성 확인

GWLBVPC 구성을 확인해 봅니다.

1. GWLB 구성
2. GWLB Target Group 구성
3. VPC Endpoint 와 Service 확인
4. Appliance 확인&#x20;

![](<.gitbook/assets/image (100).png>)

### 3.GWLB 구성&#x20;

AWS 관리 콘솔 - EC2 - 로드밸런싱 - 로드밸런서 메뉴를 선택합니다. Gateway LoadBalancer 구성을 확인할 수 있습니다. ELB 유형이 "gateway"로 구성된 것을 확인 할 수 있습니다.

![](<.gitbook/assets/image (84).png>)

### 4.GWLB Target Group 구성&#x20;

AWS 관리 콘솔 - EC2 - 로드밸런싱 - 대상 그룹을 선택합니다. GWLB가 로드밸런싱을 하게 되는 대상그룹(Target Group)을 확인 할 수 있습니다.

* &#x20;프로토콜 : GENEVE 6081 (포트 6081의 GENGEVE 프로토콜을 사용하여 모든 IP 패킷을 수신하고 리스너 규칙에 지정된 대상 그룹에 트래픽을 전달합니다.)
* 등록된 대상 : GWLB가 로드밸런싱을 하고 있는 Target 장비를 확인합니다.

![](<.gitbook/assets/image (222).png>)

AWS 관리 콘솔 - EC2 - 로드밸런싱 - 대상 그룹 - 상태검사 메뉴를 확인합니다.

ELB와 동일하게 대상그룹(Target Group)에 상태를 검사할 수 있습니다. 이 랩에서는 HTTP  Path / 를 통해서 Health Check를 하도록 구성했습니다.

![](<.gitbook/assets/image (189).png>)

### 5. VPC Endpoint Service 확인

Workload VPC(VPC01,02,03)들과 Private link로 연결하기 위해, GWLB VPC에 Endpoint Service를 구성하였습니다. 이를 확인해 봅니다.

AWS 관리 콘솔 - VPC - 엔드포인트 서비스를 선택합니다. 생성된 VPC Endpoint Service를 확인할 수 있습니다.

* 서비스 이름 - 예 com.amazonaws.vpce.ap-northeast-2.vpce-svc-03f01aa9fbb85beb4
* 유형 : GatewayLoadBalancer
* 가용영역 : ap-northeast-2a, ap-northeast-2b

2개 영역에 걸쳐서 GWLB에 대해 VPC Endpoint Service를 구성하고 있습니다.

![](<.gitbook/assets/image (190).png>)

AWS 관리 콘솔 - VPC - 엔드포인트 서비스-엔드포인트 연결를 선택합니다.

Workload VPC (VPC01,02,03)의 각 가용영역들과 연결된 것을 확인 할 수 있습니다. 각 VPC별 2개의 가용영역을 구성하였기 때문에 VPC별 2개의 Endpoint가 연결됩니다.

![](<.gitbook/assets/image (164).png>)

### 6. Appliance 확인&#x20;

AWS 관리 콘솔 - EC2 - 인스턴스 메뉴를 선택하고, "appliance" 키워드로 필터링 해 봅니다. 4개의 리눅스 기반의 appliance가 설치되어 있습니다.

![](<.gitbook/assets/image (109).png>)

Appliance 구성 정보를 확인해 봅니다.

AWS 관리콘솔 - Cloudformation - 스택을 선택하면, 앞서 배포했던 Cloudformation 스택들을 확인 할 수 있습니다. "GWLBVPC"를 선택합니다. 그리고 출력을 선택합니다. 값을 확인해 보면 공인 IP 주소를 확인 할 수 있습니다.

![](<.gitbook/assets/image (107).png>)

앞서 사전 준비에서 생성한 Cloud9에서 Appliance로 직접 접속해 봅니다.

```
#SSM 연결을 위한 Shell 실행
~/environment/gwlb/appliance_ssm.sh

```

각 Appliance에서 아래 명령을 통해 , GWLB IP와 어떻게 매핑되었는지 확인합니다. Cloud9에서 새로운 터미널 4개를 탭에서 추가해서 4개 Appliance를 모두 확인해 봅니다.

```
aws ssm start-session --target $Appliance_11_101
aws ssm start-session --target $Appliance_11_102
aws ssm start-session --target $Appliance_12_101
aws ssm start-session --target $Appliance_12_102

```

각 Appliance에서 아래 명령을 통해 , GWLB IP와 어떻게 매핑되었는지 확인합니다.

```
sudo iptables -L -n -v -t nat

```

AZ A에 배포된 Appliance는 다음과 같이 출력됩니다.

```
[ec2-user@ip-10-254-11-101 ~]$ sudo iptables -L -n -v -t nat
Chain PREROUTING (policy ACCEPT 4987 packets, 298K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  178 22464 DNAT       udp  --  eth0   *       10.254.11.60         10.254.11.101        to:10.254.11.60:6081

Chain INPUT (policy ACCEPT 4987 packets, 298K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 1315 packets, 102K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 1315 packets, 102K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  178 22464 MASQUERADE  udp  --  *      eth0    10.254.11.60         10.254.11.60         udp dpt:6081
```

GENEVE 터널링의 GWLB IP주소는 10.254.11.60  이며, Appliance IP와 터널링 된 것을 확인 할 수 있습니다.

AZ B에 배포된 Appliance는 다음과 같이 출력됩니다.

```
[ec2-user@ip-10-254-12-101 ~]$ sudo iptables -L -n -v -t nat
Chain PREROUTING (policy ACCEPT 5313 packets, 316K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  192 23456 DNAT       udp  --  eth0   *       10.254.12.149        10.254.12.101        to:10.254.12.149:6081

Chain INPUT (policy ACCEPT 5313 packets, 316K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 1626 packets, 123K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 1626 packets, 123K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  192 23456 MASQUERADE  udp  --  *      eth0    10.254.12.149        10.254.12.149        udp dpt:6081
```

GENEVE 터널링의 GWLB IP주소는 10.254.12.101  이며, Appliance IP와 터널링 된 것을 확인 할 수 있습니다.

이렇게 GWLB 에서 생성된 IP주소와 각 Appliance의 IP간에 UDP 6081 포트로 터널링되어 , 외부의 IP 주소와 내부의 IP 주소를 그대로 유지할 수 있습니다. 또한 터널링으로 인입시 5Tuple (출발지 IP, Port, 목적지 IP, Port, 프로토콜)의 정보를 TLV로 Encapsulation하여 분산처리할 때 사용합니다.

## Workload VPC 확인

이제 각 VPC에서 실제 구성과 트래픽을 확인해 봅니다.

1. VPC Endpoint 확인
2. Private Subnet Route Table 확인
3. Ingress Routing Table 확인

![](<.gitbook/assets/image (17).png>)

아래 흐름과 같이 트래픽이 처리됩니다.

1. 외부 트래픽은 인터넷 게이트웨이로 접근
2. Ingress Route Table에 의해 GWLB Endpoint로 트래픽 처리
3. Public Subnet의 VPC Endpoint는 GWLB VPC Endpoint Service로 전달
4. GWLB로 트래픽 전달
5. AZ A,AZ B Target Group으로 LB 처리 - UDP 6081 GENEVE로 Encapsulation (TLV Header - 5Tuple)
6. Appliance에서 트래픽 처리 후 다시 Return
7. Decap 해서 다시 VPC Endpoint Service로 전달
8. Public Subnet VPC Endpoint로 전달
9. Private Subnet 인스턴스로 전달&#x20;
10. Return되는 트래픽은 Private Subnet의 Route Table에 의해 VPC Endpoint로 다시 전달.

![](<.gitbook/assets/image (93).png>)

### 7.VPC Endpoint 확인

AWS 관리 콘솔 - VPC - Endpoint를 선택하여 실제 구성된 VPC Endpoint를 확인해 봅니다. 3개의 VPC에 2개씩 구성된 AZ를 위해 총 6개의 Endpoint가 구성되어 있습니다. (VPC Endpoint는 AZ Subnet당 연결됩니다.)

![](<.gitbook/assets/image (117).png>)

### 8. Private Subnet Route Table 확인

AWS 관리콘솔 - VPC - 라우팅 테이블을 선택하고 VPC01,02,03-Private-Subnet-A,B-RT 이름의 라우팅 테이블을 확인해 봅니다. Return되는 트래픽의 경로는 GWLB VPC Endpoint로 설정되어 있습니다.

![](<.gitbook/assets/image (23).png>)

![](<.gitbook/assets/image (123).png>)

### 9. Ingress Routing Table 확인

AWS 관리콘솔 - VPC - 라우팅 테이블을 선택하고 VPC01,02,03-IGW-Ingress-RT 이름의 라우팅 테이블을 확인해 봅니다.  Ingress Routing Table에 대한 구성을 확인 할 수 있습니다. VPC로 인입 되는 트래픽을 특정 경로로 보내는 역할을 합니다. 여기에서는 GWLB VPC Endpoint로 구성하도록 되어 있습니다.

![](<.gitbook/assets/image (120).png>)

![](<.gitbook/assets/image (121).png>)

## 트래픽 확인.

### 10. Workload VPC의 EC2에서 트래픽 확인

VPC 01,02,03의 EC2에서 외부로 정상적으로 트래픽이 처리되는 지 확인 해 봅니다.

Cloud9 터미널을 다시 접속해서 , VPC 01,02,03의 Private Subnet 에 배치된 EC2 인스턴스에 접속해 봅니다. Private Subnet은 직접 연결이 불가능하기 때문에 Session Manager를 통해 접속합니다.

VPC01,02,03 을 Cloudformation을 통해 배포할 때 해당 인스턴스들에 Session Manager 접속을 위한 Role과 Session Manager 연결을 위한 Endpoint가 이미 구성되어 있습니다.

아래 그림에서 처럼 확인해 볼 수 있습니다.

![](<.gitbook/assets/image (74).png>)

![](<.gitbook/assets/image (101).png>)

먼저 Cloud9에 Session Manager 기반 접속을 위해 아래와 같이 설치합니다. (이미 설치되어 있는 경우 생략합니다)

```
#session manager plugin 설치
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm" -o "session-manager-plugin.rpm"
sudo yum install -y session-manager-plugin.rpm
git clone https://github.com/whchoi98/useful-shell.git

```

session manager 기반으로 접속하기 위해, 아래 명령을 실행하여 ec2 인스턴스의 id값을 확인합니다.

```
cd ~/environment/useful-shell/
./aws_ec2_ext.sh

```

아래와 같이 결과를 확인 할 수 있습니다.

```
whchoi:~/environment/useful-shell (master) $ ./aws_ec2_ext.sh 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                                     DescribeInstances                                                                                    |
+-----------------------------------------------------------+------------------+----------------------+------------+------------------------+----------+----------------+------------------+
|  GWLBVPC-Appliance-10.254.12.101                          |  ap-northeast-2b |  i-065852170f36be268 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.254.12.101 |  3.35.5.188      |
|  GWLBVPC-Appliance-10.254.12.102                          |  ap-northeast-2b |  i-0cd6b81597257e7a0 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.254.12.102 |  3.34.28.238     |
|  VPC02-Private-B-10.2.22.102                              |  ap-northeast-2b |  i-022bfff134299b305 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.2.22.102   |  13.125.203.174  |
|  VPC01-Private-B-10.1.22.101                              |  ap-northeast-2b |  i-09ba281fa2130726a |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.1.22.101   |  13.209.2.88     |
|  VPC03-Private-B-10.3.22.101                              |  ap-northeast-2b |  i-0c3c92c6fc8c9c691 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.3.22.101   |  52.78.149.110   |
|  VPC03-Private-B-10.3.22.102                              |  ap-northeast-2b |  i-01d50385674c2884b |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.3.22.102   |  13.125.240.3    |
|  VPC01-Private-B-10.1.22.102                              |  ap-northeast-2b |  i-05e27a3db037bc1bd |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.1.22.102   |  3.35.225.49     |
|  VPC02-Private-B-10.2.22.101                              |  ap-northeast-2b |  i-0548e17996fd96d57 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.2.22.101   |  13.125.91.69    |
|  GWLBVPC-Appliance-10.254.11.102                          |  ap-northeast-2a |  i-08d1d4dda9d43e487 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.254.11.102 |  3.35.53.210     |
|  GWLBVPC-Appliance-10.254.11.101                          |  ap-northeast-2a |  i-0ba703c865a94fd04 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.254.11.101 |  3.35.55.51      |
|  VPC01-Private-A-10.1.21.102                              |  ap-northeast-2a |  i-085558b0d0c93b570 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.1.21.102   |  13.125.15.119   |
|  VPC03-Private-A-10.3.21.101                              |  ap-northeast-2a |  i-0f6869867c9c1f1ff |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.3.21.101   |  3.36.58.217     |
|  VPC03-Private-A-10.3.21.102                              |  ap-northeast-2a |  i-0c3cfe2fc1ad3a0eb |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.3.21.102   |  13.125.97.211   |
|  VPC01-Private-A-10.1.21.101                              |  ap-northeast-2a |  i-0b41f548586fc53c0 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.1.21.101   |  52.79.199.91    |
|  VPC02-Private-A-10.2.21.101                              |  ap-northeast-2a |  i-02a6ec623eb3ac8e5 |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.2.21.101   |  3.35.19.145     |
|  VPC02-Private-A-10.2.21.102                              |  ap-northeast-2a |  i-0f9c43ca89cff209d |  t3.small  |  ami-07464b2b9929898f8 |  running |  10.2.21.102   |  15.165.74.201   |
|  aws-cloud9-gwlb-console-aec439cc7860438d93a04af41e4f2364 |  ap-northeast-2d |  i-029d2fd2d6485b1d7 |  m5.xlarge |  ami-011f8bfe22440499a |  running |  172.31.63.114 |  3.36.43.51      |
+-----------------------------------------------------------+------------------+----------------------+------------+------------------------+----------+----------------+------------------+
```

session manager 명령을 통해 해당 인스턴스에 연결해 봅니다. (VPC01-Private-A-10.1.21.101)

```
# aws ssm start-session --target {VPC01-Private-A-10.1.21.101 Instance ID}
aws ec2 describe-instances --filters 'Name=tag:Name,Values=VPC01-Private-A-10.1.21.101' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId'
export VPC01_Private_A_10_1_21_101=$(aws ec2 describe-instances --filters 'Name=tag:Name,Values=VPC01-Private-A-10.1.21.101' 'Name=instance-state-name,Values=running' | jq -r '.Reservations[].Instances[].InstanceId')
echo "export VPC01_Private_A_10_1_21_101=${VPC01_Private_A_10_1_21_101}"| tee -a ~/.bash_profile
source ~/.bash_profile

aws ssm start-session --target $VPC01_Private_A_10_1_21_101

```

터미널에 접속한 후에 , 아래 명령을 통해 bash로 접근해서 외부로 트래픽을 전송해 봅니다.

```
sudo -s
ping www.aws.com

```

아래와 같은 결과를 확인할 수 있습니다.

```
whchoi:~/environment/useful-shell (master) $ aws ssm start-session --target i-0b41f548586fc53c0

Starting session with SessionId: whchoi-01dc306dd4b046251
sh-4.2$ sudo -s
[root@ip-10-1-21-101 bin]# ping www.aws.com
PING aws.com (54.230.62.60) 56(84) bytes of data.
64 bytes from server-54-230-62-60.icn54.r.cloudfront.net (54.230.62.60): icmp_seq=1 ttl=240 time=2.51 ms
64 bytes from server-54-230-62-60.icn54.r.cloudfront.net (54.230.62.60): icmp_seq=2 ttl=240 time=2.08 ms
64 bytes from server-54-230-62-60.icn54.r.cloudfront.net (54.230.62.60): icmp_seq=3 ttl=240 time=2.08 ms
```

### 11. Appliance에서 확인

앞서 Session manager를 통해 www.aws.com으로 ping을 실행했습니다. 해당 터미널을 실행한 상태에서 Cloud9 터미널을 2개로 추가로 열어 봅니다.&#x20;

아래와 같이 2개의 Appliance에 SSH로 연결해서 명령을 실행해 보고, Appliance로 Traffic이 들어오는지 확인해 봅니다.

Cloud9 터미널 1

```
aws ssm start-session --target $VPC01_Private_A_10_1_21_101
sudo tcpdump -nvv 'port 6081'
sudo tcpdump -nvv 'port 6081'| grep 'ICMP'

```

Cloud9 터미널 2

```
aws ssm start-session --target $VPC01_Private_A_10_1_21_102
sudo tcpdump -nvv 'port 6081'
sudo tcpdump -nvv 'port 6081'| grep 'ICMP'

```

다음과 같이 1개의 터미널에서 icmp가 처리되는 것을 확인 할 수 있습니다.

```
[ec2-user@ip-10-254-11-101 ~]$ sudo tcpdump -nvv 'port 6081'| grep 'ICMP'
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
15:58:04.744658 IP (tos 0x0, ttl 255, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.60.60001 > 10.254.11.101.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data 2356de92 d389839c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 98ef1b00]
        IP (tos 0x0, ttl 254, id 27551, offset 0, flags [DF], proto ICMP (1), length 84)
    10.1.21.101 > 54.230.62.60: ICMP echo request, id 1591, seq 370, length 64
15:58:04.744689 IP (tos 0x0, ttl 254, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.101.60001 > 10.254.11.60.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data 2356de92 d389839c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 98ef1b00]
        IP (tos 0x0, ttl 254, id 27551, offset 0, flags [DF], proto ICMP (1), length 84)
    10.1.21.101 > 54.230.62.60: ICMP echo request, id 1591, seq 370, length 64
15:58:04.746459 IP (tos 0x0, ttl 255, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.60.60001 > 10.254.11.101.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data 2356de92 d389839c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 98ef1b00]
        IP (tos 0x0, ttl 241, id 28778, offset 0, flags [none], proto ICMP (1), length 84)
    54.230.62.60 > 10.1.21.101: ICMP echo reply, id 1591, seq 370, length 64
15:58:04.746476 IP (tos 0x0, ttl 254, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.101.60001 > 10.254.11.60.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data 2356de92 d389839c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 98ef1b00]
        IP (tos 0x0, ttl 241, id 28778, offset 0, flags [none], proto ICMP (1), length 84)
    54.230.62.60 > 10.1.21.101: ICMP echo reply, id 1591, seq 370, length 64
```

Source IP와  Destination IP가 모두 유지된 채로 통신하는 것을 확인 할 수 있습니다.&#x20;

이제 다른 VPC와 다른 서브넷의 EC2에서도 트래픽이 정상적으로 처리되는지 확인해 봅니다.

## 자원 삭제

AWS 관리콘솔 - Cloudformation - 스택 을 선택하고 생성된 Stack을 , 생성된 역순으로 삭제합니다.

VPC01,VPC02,VPC03-GWLBVPC 순으로 삭제합니다.(Cloud9은 계속 사용하기 위해 삭제 하지 않습니다.)  VPC01,02,03이 완전히 삭제된후, GWLBVPC를 삭제 합니다.

```
aws cloudformation delete-stack --stack-name VPC01
aws cloudformation delete-stack --stack-name VPC02
aws cloudformation delete-stack --stack-name VPC03

```

1. VPC01,02,03 선택 후 삭제 (3\~4분 소요 , 동시진행 가능)
2. GWLBVPC 선택 후 삭제 (3\~4분 소요)

![](<.gitbook/assets/image (149).png>)

랩을 완전히 종료하려면 **`AWS 관리콘솔 - Cloudformation - 스택`**  aws cloud9 콘솔 스택도 삭제합니다.
