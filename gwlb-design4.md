---
description: 'Update : 2023-01-16/ 1h /Cloudformation CLI 배포로 변경'
---

# GWLB Desing 4

## 목표 구성 개요

2개의 각 워크로드 VPC (VPC01,02)은 Account내에 구성된 GWLB 기반의 보안 VPC를 통해서 내, 외부 트래픽을 처리하는 구성입니다. GWLB 기반의 보안 VPC는 2개의 AZ에 4개의 가상 Appliance가 로드밸런싱을 통해 처리 됩니다.

이러한 구성은 VPC Endpoint를 특정 VPC에 구성하고, TransitGateway를 통해 GWLB에 VPC Endpoint Service를 연결하는 중앙집중 구조입니다.

GWLB Design2와 다른 점은 ALB(Application Load Balancer)를 GWLB와 연계하는 VPC에 배치해서, 내부의 VPC01,02의 서비스들이 외부에 제공하도록 한다는 점입니다.

아래 그림은 목표 구성도 입니다.

{% embed url="https://youtu.be/Es35y0mtT0w" %}

![](<.gitbook/assets/image (219).png>)

## Cloudformation기반 VPC 배포

### 1.VPC yaml 파일 다운로드

Cloud9 콘솔에서 아래 github로 부터 VPC yaml 파일을 다운로드 합니다. (앞서 다운로드 하였으면 생략합니다.)

```
git clone https://github.com/whchoi98/gwlb.git

```

아래와 같은 순서로 Cloudformation에서 Yaml파일을 배포합니다.

1. GWLBVPC.yml
2. N2SVPC.yml
3. VPC01.yml, VPC02.yml
4. GWLBTGW.yml

{% hint style="info" %}
계정에서 VPC 기본 할당량은 Default VPC 포함 5개입니다. 이 랩에서는 VPC03 은 생성하지 않습니다.
{% endhint %}

### 2.GWLB VPC 배포

Cloud9 터미널에서 GWLBVPC를 배포합니다

스택 세부 정보 지정에서 , 스택이름과 VPC Parameters를 지정합니다. 대부분 기본값을 사용하면 됩니다.

* 스택이름 : GWLBVPC
* AvailabilityZone A : ap-northeast-2a
* AvailabilityZone B : ap-northeast-2b
* VPCCIDRBlock: 10.254.0.0/16
* PublicSubnetABlock: 10.254.11.0/24
* PublicSubnetBBlock: 10.254.12.0/24
* InstanceTyep: t3.small
* KeyPair : 사전에 만들어 둔 keyPair를 사용합니다. (예. mykey)

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "GWLBVPC" \
  --template-file "/home/ec2-user/environment/gwlb/Case4/1.Case4-GWLBVPC.yml" \
  --parameter-overrides "KeyPair=$KeyName" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

3\~4분 후에 GWLBVPC가 완성됩니다.

**`AWS 관리콘솔 - VPC - 가상 프라이빗 클라우드 - 엔드포인트 서비스`** 를 선택합니다. Cloudformation을 통해서 VPC Endpoint 서비스가 이미 생성되어 있습니다. 이것을 선택하고 \*\*`세부 정보`\*\*를 확인합니다.

서비스 이름을 복사해 둡니다. 뒤에서 생성할 VPC들의 Cloudformation에서 사용할 것입니다.

![](<.gitbook/assets/image (111).png>)

VPCEndpointServiceName 값을 아래에서 처럼 환경변수에 저장해 둡니다. &#x20;

```
export VPCEndpointServiceName4=$(aws ec2 describe-vpc-endpoint-services --filter "Name=service-type,Values=GatewayLoadBalancer" | jq -r '.ServiceNames[]')
echo $VPCEndpointServiceName4
echo "export VPCEndpointServiceName4=${VPCEndpointServiceName4}" | tee -a ~/.bash_profile
source ~/.bash_profile

```

### 3.N2SVPC 배포

외부 인터넷으로 통신하는 North-South 트래픽 처리를 하는 VPC를 생성합니다.

N2SVPC를 Cloudformation에서 앞서 과정과 동일하게 생성합니다. 다운로드 받은 Yaml 파일들 중에 N2SVPC 선택해서 생성합니다.스택 이름을 생성하고, GWLBVPC의 VPC Endpoint 서비스 이름을 **`"VPCEndpointServiceName"`** 에 입력합니다. 또한 나머지 파라미터들도 입력합니다. 대부분 기본값을 사용합니다.

* 스택이름 : N2SVPC
* AvailabilityZone A : ap-northeast-2a
* AvailabilityZone B : ap-northeast-2b
* VPCCIDRBlock: 10.11.0.0
* GWLBeSubnetABlock:10.11.1.0/24
* GWLBeSubnetBBlock:10.11.2.0/24
* PublicSubnetABlock: 10.11.11.0/24
* PublicSubnetBBlock: 10.11.12.0/24
* PrivateSubnetABlock:10.11.21.0/24
* PrivateSubnetBBlock:10.11.22.0/24
* TGWSubnetABlock:10.11.251.0/24
* TGWSubnetBBlock:10.11.252.0/24
* DefaultRouteBlock: 0.0.0.0/0 (Default Route Table 주소를 선언합니다.)
* VPC1CIDRBlock : 10.1.0.0/16 (VPC1의 CIDR Block 주소를 선언합니다.)
* VPC2CIDRBlock: 10.2.0.0/16 (VPC2의 CIDR Block 주소를 선언합니다.)
* VPCEndpointServiceName : 앞서 복사해둔 GWLBVPC의 VPC endpoint service name을 입력합니다.
* InstanceTyep: t3.small
* KeyPair : 사전에 만들어 둔 keyPair를 사용합니다.(예.mykey)

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "N2SVPC" \
  --template-file "/home/ec2-user/environment/gwlb/Case4/2.Case4-N2SVPC.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
    "VPCEndpointServiceName=$VPCEndpointServiceName4" \
  --capabilities CAPABILITY_NAMED_IAM
```

### 4.VPC01,02 배포

**나머지 VPC01,VPC02,VPC03 의 Cloudformation Yaml 파일을 업로드 합니다.**

{% hint style="info" %}
VPC는 계정당 기본 5개가 할당되어 있습니다. 1개는 Default VPC로 사용 중이고, 4개를 사용 가능하므로 일반 계정에서는 GWLBVPC, N2SVPC, VPC01,VPC02 까지만 생성 가능합니다.
{% endhint %}

* 스택이름 : VPC01,VPC02
* AvailabilityZone A : ap-northeast-2a
* AvailabilityZone B : ap-northeast-2b
* VPCCIDRBlock: 10.1.0.0 (VPC01), 10.2.0.0 (VPC02)
* PrivateSubnetABlock:10.1.21.0/24 (VPC01), 10.2.22.0/24(VPC02)
* PrivateSubnetBBlock:10.1.22.0/24 (VPC01), 10.2.22.0/24(VPC02)
* TGWSubnetABlock:10.1.251.0/24 (VPC01), 10.2.251.0/24 (VPC02)
* TGWSubnetBBlock:10.1.252.0/24 (VPC01), 10.2.252.0/24 (VPC02)
* InstanceTyep: t3.small
* KeyPair : 사전에 만들어 둔 keyPair를 사용합니다.(예. gwlbkey)

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "VPC01" \
  --template-file "/home/ec2-user/environment/gwlb/Case4/3.Case4-VPC01.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "VPC02" \
  --template-file "/home/ec2-user/environment/gwlb/Case4/4.Case4-VPC02.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

아래와 같이 VPC가 모두 정상적으로 설정되었는지 확인해 봅니다.

**`AWS 관리 콘솔 - VPC 대시 보드 - VPC`**

![](<.gitbook/assets/image (52).png>)

**`AWS 관리 콘솔 - VPC 대시 보드 - 서브넷`**

![](<.gitbook/assets/image (91).png>)

### 5. TransitGateway 배포

N2SVPC, VPC01,VPC02을 연결하기 위한 TransitGateway를 배포합니다. 앞서 git을 통해 다운 받은 파일 중 GWLBTGW.yml 파일을 Cloudformation을 통해서 배포합니다.

* Stack Name : GWLBTGW
* DefaultRouteBlock: 0.0.0.0/0
* VPC01CIDRBlock: 10.1.0.0/16
* VPC02CIDRBlock: 10.2.0.0/16

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "GWLBTGW" \
  --template-file "/home/ec2-user/environment/gwlb/Case4/5.Case4-GWLBTGW.yml" 
```

### 6. 라우팅 테이블 확인

TransitGateway 구성과 RouteTable을 아래에서 확인합니다. Egress(VPC에서 외부로 향하는) 에 대한 각 테이블을 확인하고 , 이후 Ingress (IGW에서 내부로 향하는)에 대한 테이블을 확인해 봅니다.

![](<.gitbook/assets/image (141).png>)

**`AWS 관리콘솔 - VPC - 라우팅 테이블`** 을 선택하고, **`"VPC01-Private-Subnet-A,B-RT"`**의 **`라우팅`**을 확인합니다.

![](<.gitbook/assets/image (143).png>)

**`AWS 관리콘솔 - TransitGateway`** 를 선택하고, **`"GWLBTGW"`** 라는 이름으로 **`TransitGateway`**가 정상적으로 생성되었는지 확인합니다.

![](<.gitbook/assets/image (104).png>)

**`AWS 관리콘솔 - TransitGateway - TransitGateway Attachment(연결)`** 을 선택하고, 각 VPC에 연결된 Attachment를 확인해 봅니다.

![](<.gitbook/assets/image (132).png>)

**`AWS 관리콘솔 - TransitGateway - TransitGateway 라우팅테이블`**을 선택하고, **`"GWLBTGW-RT-VPC-OUT"`** 을 선택해서, TGW에서 트래픽이 외부로 가는 라우팅을 확인해 봅니다.

![](<.gitbook/assets/image (70).png>)

**`AWS 관리콘솔 - VPC - 라우팅 테이블`** 을 선택하고, **`"N2SVPC-Private-Subnet-A,B-RT"`**의 **`라우팅`**을 확인합니다.

![](<.gitbook/assets/image (24).png>)

**`AWS 관리콘솔 - VPC - 라우팅 테이블`** 을 선택하고, **`"N2SVPC-Public-Subnet-A,B-RT"`**의 **`라우팅`**을 확인합니다.

![](<.gitbook/assets/image (135).png>)

**`AWS 관리콘솔 - VPC - 라우팅 테이블`** 을 선택하고, **`"N2SVPC-GWLBe-Subnet-A,B-RT"`**의 **`라우팅`**을 확인합니다.

![](<.gitbook/assets/image (171).png>)

**`AWS 관리콘솔 - VPC - 라우팅 테이블`** 을 선택하고, **`"N2SVPC-IGW-Ingress-RT"`**의 **`라우팅`**을 확인합니다.

![](<.gitbook/assets/image (83).png>)

## GWLB 구성 확인

GWLBVPC 구성을 확인해 봅니다.

1. GWLB 구성
2. GWLB Target Group 구성
3. VPC Endpoint 와 Service 확인
4. Appliance 확인

![](<.gitbook/assets/image (122).png>)

### 7.GWLB 구성

**`AWS 관리 콘솔 - EC2 - 로드밸런싱 - 로드밸런서`** 메뉴를 선택합니다. Gateway LoadBalancer 구성을 확인할 수 있습니다. ELB 유형이 **`"gateway"`**로 구성된 것을 확인 할 수 있습니다.

![](<.gitbook/assets/image (39).png>)

### 8.GWLB Target Group 구성

**`AWS 관리 콘솔 - EC2 - 로드밸런싱 - 대상 그룹`**을 선택합니다. GWLB가 로드밸런싱을 하게 되는 대상그룹(Target Group)을 확인 할 수 있습니다.

* 프로토콜 : **`GENEVE 6081`** (포트 6081의 GENGEVE 프로토콜을 사용하여 모든 IP 패킷을 수신하고 리스너 규칙에 지정된 대상 그룹에 트래픽을 전달합니다.)
* 등록된 대상 : GWLB가 로드밸런싱을 하고 있는 Target 장비를 확인합니다.

![](<.gitbook/assets/image (173).png>)

**`AWS 관리 콘솔 - EC2 - 로드밸런싱 - 대상 그룹 - 상태검사`** 메뉴를 확인합니다.

ELB와 동일하게 대상그룹(Target Group)에 상태를 검사할 수 있습니다. 이 랩에서는 HTTP Path / 를 통해서 **`Health Check`**를 하도록 구성했습니다.

![](<.gitbook/assets/image (94).png>)

### 9. VPC Endpoint Service 확인

N2SVPC Private link로 연결하기 위해, GWLB VPC에 Endpoint Service를 구성하였습니다. 이를 확인해 봅니다.

**`AWS 관리 콘솔 - VPC - 엔드포인트 서비스`**를 선택합니다. 생성된 VPC Endpoint Service를 확인할 수 있습니다.

* 서비스 이름 - 예 com.amazonaws.vpce.ap-northeast-2.vpce-svc-082d152b9180f8ad0
* 유형 : GatewayLoadBalancer
* 가용영역 : ap-northeast-2a, ap-northeast-2b

2개 영역에 걸쳐서 GWLB에 대해 VPC Endpoint Service를 구성하고 있습니다.

![](<.gitbook/assets/image (124).png>)

**`AWS 관리 콘솔 - VPC - 엔드포인트 서비스-엔드포인트 연결`**를 선택합니다.

N2SVPC의 각 가용영역들과 연결된 것을 확인 할 수 있습니다. VPC별 2개의 가용영역의 Private Subnet에 배치된 VPC Endpoint에 연결된 것을 확인 합니다.

![](<.gitbook/assets/image (35).png>)

### 10. Appliance 확인

**`AWS 관리 콘솔 - EC2 - 인스턴스`** 메뉴를 선택하고, "appliance" 키워드로 필터링 해 봅니다. 4개의 리눅스 기반의 appliance가 설치되어 있습니다.

![](<.gitbook/assets/image (61).png>)

Appliance 구성 정보를 확인해 봅니다.

**`AWS 관리콘솔 - Cloudformation - 스택`**을 선택하면, 앞서 배포했던 Cloudformation 스택들을 확인 할 수 있습니다. **`"GWLBVPC"`**를 선택합니다. 그리고 출력을 선택합니다. 값을 확인해 보면 공인 IP 주소를 확인 할 수 있습니다.

![](<.gitbook/assets/image (77).png>)

앞서 사전 준비에서 생성한 Cloud9 터미널에서 Appliance로 직접 접속해 봅니다.

```
#기존 Appliance 정보를 삭제
sudo sed '/Appliance/d' ~/.bash_profile

#SSM 연결을 위한 Shell 실행
~/environment/gwlb/appliance_ssm.sh
source ~/.bash_profile
```

각 Appliance에서 아래 명령을 통해 , GWLB IP와 어떻게 매핑되었는지 확인합니다. Cloud9에서 새로운 터미널 4개를 탭에서 추가해서 4개 Appliance를 모두 확인해 봅니다.

```
# Appliance 11.101
aws ssm start-session --target $Appliance_11_101

# Appliance 11.102
aws ssm start-session --target $Appliance_11_102

# Appliance 12.101
aws ssm start-session --target $Appliance_12_101

# Appliance 12.102
aws ssm start-session --target $Appliance_12_102

```

각 Appliance에서 아래 명령을 통해 , GWLB IP와 어떻게 매핑되었는지 확인합니다.

```
aws ssm start-session --target $Appliance_11_101
sudo -s
sudo iptables -L -n -v -t nat

```

AZ A에 배포된 Appliance는 다음과 같이 출력됩니다.

```
[ec2-user@ip-10-254-11-101 ~]$ sudo iptables -L -n -v -t nat
Chain PREROUTING (policy ACCEPT 26562 packets, 1587K bytes)
 pkts bytes target     prot opt in     out     source               destination         
18792 2579K DNAT       udp  --  eth0   *       10.254.11.64         10.254.11.101        to:10.254.11.64:6081

Chain INPUT (policy ACCEPT 26562 packets, 1587K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 20849 packets, 1611K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 20849 packets, 1611K bytes)
 pkts bytes target     prot opt in     out     source               destination         
18792 2579K MASQUERADE  udp  --  *      eth0    10.254.11.64         10.254.11.64         udp dpt:6081
```

GENEVE 터널링의 GWLB IP주소는 10.254.11.101 이며, Appliance IP와 터널링 된 것을 확인 할 수 있습니다.

AZ B에 배포된 Appliance는 다음과 같이 출력됩니다.

```
sudo iptables -L -n -v -t nat

```

```
[ec2-user@ip-10-254-12-101 ~]$ sudo iptables -L -n -v -t nat
Chain PREROUTING (policy ACCEPT 26358 packets, 1578K bytes)
 pkts bytes target     prot opt in     out     source               destination         
19195 2608K DNAT       udp  --  eth0   *       10.254.12.122        10.254.12.101        to:10.254.12.122:6081

Chain INPUT (policy ACCEPT 26358 packets, 1578K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 20713 packets, 1600K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 20713 packets, 1600K bytes)
 pkts bytes target     prot opt in     out     source               destination         
19195 2608K MASQUERADE  udp  --  *      eth0    10.254.12.122        10.254.12.122        udp dpt:6081
```

GENEVE 터널링의 GWLB IP주소는 10.254.12.101 이며, Appliance IP와 터널링 된 것을 확인 할 수 있습니다.

이렇게 GWLB 에서 생성된 IP주소와 각 Appliance의 IP간에 UDP 6081 포트로 터널링되어 , 외부의 IP 주소와 내부의 IP 주소를 그대로 유지할 수 있습니다. 또한 터널링으로 인입시 5Tuple (출발지 IP, Port, 목적지 IP, Port, 프로토콜)의 정보를 TLV로 Encapsulation하여 분산처리할 때 사용합니다.

## 트래픽 확인&#x20;

### 11. 트래픽 확인&#x20;

아래와 같은 트래픽 흐름으로 VPC 에서 외부로 트래픽을 처리하게 됩니다.&#x20;

![](<.gitbook/assets/image (199).png>)

1. VPC01,02 Private Subnet Instance에서 TGW 로 트래픽 전송 (Private Subnet Routing Table 참조)
2. TGW에서 VPC01의 Attachment 로 연결된 라우팅 테이블을 참조
3. TGW에서 라우팅 테이블을 참조해서 N2VPC로 트래픽 전송
4. N2SVPC NAT Gateway로 전송 (Private Subnet Routing Table 참조)
5. N2SVPC Public Subnet 에서 GWLB VPC Endpoint로 전송 (Public Subnet Routing Table 참조)
6. N2SVPC GWLB VPC Endpoint에서 GWLB VPC의 VPC Endpoint Service 로 전송
7. GWLB VPC Endpoint Service에서 GWLB로 전송
8. GWLB에서 AZ A 또는 AZ B Target Group으로 LB 처리 - UDP 6081 GENEVE로 Encapsulation (TLV Header - 5Tuple)
9. Appliance에서 트래픽 처리 후 Return
10. GWLB에서 Decap후 VPC Endpoint Service 전달
11. N2SVPC GWLBe Subnet에서 라우팅을 통해 IGW전달
12. IGW에서 인터넷으로 트래픽 처리

### 12. Egress 트래픽 확인&#x20;

VPC01,02의 EC2에서 외부로 정상적으로 트래픽이 처리되는 지 확인 해 봅니다.

Cloud9 터미널을 다시 접속해서 , VPC 01,02의 Private Subnet 에 배치된 EC2 인스턴스에 접속해 봅니다. Private Subnet은 직접 연결이 불가능하기 때문에 Session Manager를 통해 접속합니다.

VPC01,02 을 Cloudformation을 통해 배포할 때 해당 인스턴스들에 Session Manager 접속을 위한 Role과 Session Manager 연결을 위한 Endpoint가 이미 구성되어 있습니다.

```
##############################################
# Create-Private-EC2: VPC Private EC2 Create #
##############################################

  PrivateAInstanace1:
    Type: AWS::EC2::Instance
    DependsOn: PrivateSubnetA
    Properties:
      SubnetId: !Ref PrivateSubnetA
      ImageId: !Ref LatestAmiId
      PrivateIpAddress: 10.1.21.101
      InstanceType: !Ref InstanceType
      SecurityGroupIds: 
        - Ref: PrivateEC2SG
      KeyName: !Ref KeyPair
      IamInstanceProfile: !Ref InstanceProfileSSM
#생략 
###############################################
# Create-SSM: Create PrivateServer ServerRole #
###############################################

  ServerRoleSSM:
    Type: AWS::IAM::Role
    Properties:
      RoleName: !Sub '${AWS::StackName}-SSMRole'
      Path: "/"
      ManagedPolicyArns:
        - "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
      AssumeRolePolicyDocument:
        Version: "2012-10-17"
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - ec2.amazonaws.com
            Action:
              - sts:AssumeRole

  InstanceProfileSSM:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: "/"
      Roles: 
        - Ref: ServerRoleSSM
  #이하 생략 
```

아래 그림에서 처럼 확인해 볼 수 있습니다.

**`AWS 관리콘솔 - VPC 대시보드 - VPC - 앤드포인트`** 에서 SSM(Session Manager) 관련 VPC Endpoint 배포를 확인해 봅니다.

![](<.gitbook/assets/image (115).png>)

**`AWS 관리콘솔 - EC2 대시보드 - 인스턴스`** 에서 VPC1,2 인스턴스를 선택하고 IAM Profile이 정상적으로 구성되었는지 확인합니다.

![](<.gitbook/assets/image (37).png>)

먼저 Cloud9에 Session Manager 기반 접속을 위해 아래와 같이 설치합니다. **(GWLB Design1 에서 설치하였으면 생략합니다.)**

```
#session manager plugin 설치.
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
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                                     DescribeInstances                                                                                    |
+------------------------------------------------------------+------------------+----------------------+-----------+------------------------+----------+----------------+------------------+
|  GWLBVPC-Appliance-10.254.12.102                           |  ap-northeast-1c |  i-08a76da6cfa9eb9c2 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.254.12.102 |  54.199.252.186  |
|  GWLBVPC-Appliance-10.254.12.101                           |  ap-northeast-1c |  i-01130255cdc13d19a |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.254.12.101 |  18.183.158.149  |
|  N2SVPC-Private-B-10.11.22.102                             |  ap-northeast-1c |  i-0ae96dfdae54472fd |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.11.22.102  |  None            |
|  N2SVPC-Private-B-10.11.22.101                             |  ap-northeast-1c |  i-0ccefe913a33175c5 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.11.22.101  |  None            |
|  VPC02-Private-B-10.2.22.102                               |  ap-northeast-1c |  i-06623017c61282eaa |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.2.22.102   |  3.115.14.25     |
|  VPC01-Private-B-10.1.22.101                               |  ap-northeast-1c |  i-0c22eab7c0b387f83 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.1.22.101   |  13.115.164.161  |
|  VPC02-Private-B-10.2.22.101                               |  ap-northeast-1c |  i-093fdba8091fb0c6b |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.2.22.101   |  52.194.238.190  |
|  VPC01-Private-B-10.1.22.102                               |  ap-northeast-1c |  i-0d836294742ac5bdd |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.1.22.102   |  18.181.77.249   |
|  GWLBVPC-Appliance-10.254.11.101                           |  ap-northeast-1a |  i-0efb209a84dcd3388 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.254.11.101 |  13.112.190.73   |
|  GWLBVPC-Appliance-10.254.11.102                           |  ap-northeast-1a |  i-0513dad7d9423fa47 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.254.11.102 |  52.69.76.12     |
|  N2SVPC-Private-A-10.11.21.101                             |  ap-northeast-1a |  i-0203bfc09263493e2 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.11.21.101  |  None            |
|  N2SVPC-Private-A-10.11.21.102                             |  ap-northeast-1a |  i-0ae47b46e6170204b |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.11.21.102  |  None            |
|  VPC01-Private-A-10.1.21.101                               |  ap-northeast-1a |  i-08ad57b556da819be |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.1.21.101   |  13.231.230.85   |
|  VPC02-Private-A-10.2.21.102                               |  ap-northeast-1a |  i-0ec2592902f10350e |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.2.21.102   |  54.178.90.155   |
|  VPC02-Private-A-10.2.21.101                               |  ap-northeast-1a |  i-0e647aae3511b6c58 |  t3.small |  ami-09ebacdc178ae23b7 |  running |  10.2.21.101   |  3.112.251.135   |
```

session manager 명령을 통해 해당 인스턴스에 연결해 봅니다. (예. VPC01-Private-A-10.1.21.101)

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

아래와 같은 결과를 확인할 수 있습니다. 해당 터미널에서 ping을 계속 실행해 둡니다.

```
whchoi:~/environment $ aws ssm start-session --target i-014b816ced3052e9f

Starting session with SessionId: whchoi-07f86055a80837cd0
sh-4.2$ sudo -s
[root@ip-10-1-21-101 bin]# ping www.aws.com
PING aws.com (99.86.206.123) 56(84) bytes of data.
64 bytes from server-99-86-206-123.icn51.r.cloudfront.net (99.86.206.123): icmp_seq=1 ttl=235 time=3.48 ms
64 bytes from server-99-86-206-123.icn51.r.cloudfront.net (99.86.206.123): icmp_seq=2 ttl=235 time=2.39 ms
64 bytes from server-99-86-206-123.icn51.r.cloudfront.net (99.86.206.123): icmp_seq=3 ttl=235 time=2.37 ms

```

앞서 Session manager를 통해 [www.aws.com으로](http://www.aws.xn--com-ky7m580d/) ping을 실행했습니다. 해당 터미널을 실행한 상태에서 Cloud9 터미널을 2개로 추가로 열어 봅니다.

아래와 같이 2개의 Appliance에 SSH로 연결해서 명령을 실행해 보고, Appliance로 Traffic이 들어오는지 확인해 봅니다.

Cloud9 터미널 1

```
aws ssm start-session --target $Appliance_11_101
sudo -s
sudo tcpdump -nvv 'port 6081' | grep 'ICMP'

```

Cloud9 터미널 2

```
aws ssm start-session --target $Appliance_11_102
sudo -s
sudo tcpdump -nvv 'port 6081' | grep 'ICMP'

```

다음과 같이 1개의 터미널에서 icmp가 처리되는 것을 확인 할 수 있습니다.

```
[ec2-user@ip-10-254-11-102 ~]$ sudo tcpdump -nvv 'port 6081' | grep 'ICMP'
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
        IP (tos 0x0, ttl 252, id 61170, offset 0, flags [DF], proto ICMP (1), length 84)
    10.11.11.136 > 13.249.149.121: ICMP echo request, id 50889, seq 18, length 64
        IP (tos 0x0, ttl 252, id 61170, offset 0, flags [DF], proto ICMP (1), length 84)
    10.11.11.136 > 13.249.149.121: ICMP echo request, id 50889, seq 18, length 64
        IP (tos 0x0, ttl 233, id 47718, offset 0, flags [none], proto ICMP (1), length 84)
    13.249.149.121 > 10.11.11.136: ICMP echo reply, id 50889, seq 18, length 64
        IP (tos 0x0, ttl 233, id 47718, offset 0, flags [none], proto ICMP (1), length 84)
    13.249.149.121 > 10.11.11.136: ICMP echo reply, id 50889, seq 18, length 64
        IP (tos 0x0, ttl 252, id 61267, offset 0, flags [DF], proto ICMP (1), length 84)
    10.11.11.136 > 13.249.149.121: ICMP echo request, id 50889, seq 19, length 64
        IP (tos 0x0, ttl 252, id 61267, offset 0, flags [DF], proto ICMP (1), length 84)
    10.11.11.136 > 13.249.149.121: ICMP echo request, id 50889, seq 19, length 64
        IP (tos 0x0, ttl 233, id 47763, offset 0, flags [none], proto ICMP (1), length 84)

```

Source IP와 Destination IP가 모두 유지된 채로 통신하는 것을 확인 할 수 있습니다.

이제 다른 VPC(VPC01,VPC02)와 다른 서브넷의 EC2에서도 트래픽이 정상적으로 처리되는지 확인해 봅니다.

### 13. Ingress 트래픽 확인

GWLB Design 4 랩에서는 외부에서 N2SVPC의 ALB의 공인 DNS A레코드로 접근하기 위해, GWLB VPC의 Appliacne 보안 장비를 통과한 이후에 다시 N2SVPC ALB 접근 이후 , Target Group을 VPC01,02로 구성해서 웹 서비스를 제공하는 방식을 구성했습니다.

아래와 같은 도식으로 외부에서 내부로 웹서비스나 기타 퍼블릭 서비스를 제공할 수 있습니다.

![](<.gitbook/assets/image (22).png>)

1. 외부에 노출된 ALB DNS A 레코드로 접근 합니다.
2. IGW에서 Ingress Routing을 통해 N2SVPC GWLB VPC Endpoint로 접근합니다.\
   (ALB의 내부 주소는 10.11.11.0/24,10.11.12.0/24 이고 , Ingress Routing Table에서는 VPC Endpoint로 목적지를 설정해 두었습니다.)
3. N2SVPC GWLB VPC Endpoint에서 GWLB VPC의 VPC Endpoint Service로 트래픽을 전송합니다.
4. GWLB에서 AZ A 또는 AZ B Target Group으로 LB 처리 - UDP 6081 GENEVE로 Encapsulation (TLV Header - 5Tuple)
5. Appliance에서 트래픽 처리 후 Return
6. GWLB에서 Decap후 VPC Endpoint Service 전달
7. VPC Endpoint Service 를 통해서 GWLBe  Subnet으로 전달
8. GWLB Subnet에서 ALB로 전달
9. ALB에서 VPC01,02 Target Group으로 전달.

### 14. 인스턴스 패키지 설치&#x20;

VPC01,02의 EC2 인스턴스는 GWLB TGW(TransitGateway)가 생성된 이후 부터 인터넷이 가능했습니다. 아직까지 어떠한 패치나 패키지 설치가 이루어 지지 않았습니다.

AWS의 Resource Group 구성과 System Manager RunBook을 통해서 , Shell을 동시에 8개를 수행합니다.

**`AWS 관리콘솔 - Resource Group & Tag Editor`** 를 실행하고, **`리소스 그룹 생성`**을 선택합니다.

![](<.gitbook/assets/image (163).png>)

아래와 같이 퀴리 기반 그룹을 생성합니다.

![](<.gitbook/assets/image (31).png>)

![](<.gitbook/assets/image (50).png>)

* **`그룹 유형 : Cloudformation 스택기반`**
* **`그룹화 기준 - Cloudformation 스택 : VPC01`**
* **`그룹화 기준 - Cloudformation 스택의 리소스 유형 : AWS::EC2::Instance`**
* **`그룹리소스 미리보기 선택`**&#x20;
* **`그룹 세부 정보 : VPC01-Private-Instance`**

반복해서 VPC02 도 구성합니다.

* **`그룹 유형 : Cloudformation 스택기반`**
* **`그룹화 기준 - Cloudformation 스택 : VPC02`**
* **`그룹화 기준 - Cloudformation 스택의 리소스 유형 : AWS::EC2::Instance`**
* **`그룹리소스 미리보기 선택`**&#x20;
* **`그룹 세부 정보 : VPC02-Private-Instance`**

생성된 Resource Group을 **`"저장된 리소스 그룹"`** 에서 확인해 봅니다.

![](<.gitbook/assets/image (44).png>)

**`AWS 관리콘솔 - System Manager`** 를 실행하고, **`"Run Command"`** 를 빠른 설정 메뉴에서 선택합니다.

**`명령 실행`**을 선택합니다.

![](<.gitbook/assets/image (29).png>)

**`명령 실행`**에서 **`AWS-RunShellScript`** 를 선택합니다.

![](<.gitbook/assets/image (76).png>)

명령 파라미터에서 아래 Shell 값을 입력합니다.

```
#!/bin/bash
sudo yum -y update;
sudo yum -y install yum-utils; 
sudo yum -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm;
sudo yum -y install iotop iperf3 iptraf tcpdump git bash-completion; 
sudo yum -y install httpd php mysql php-mysql; 
sudo yum -y install python-pip;
sudo yum -y install nethogs iftop lnav nmon tmux wireshark vsftpd ftp golang;
sudo systemctl start httpd;
sudo systemctl enable httpd;
cd /var/www/html/;
sudo git clone https://github.com/whchoi98/ec2meta-webpage.git;
sudo systemctl restart httpd;
exit;

```

![](<.gitbook/assets/image (33).png>)

대상에서 리소스그룹을 선택하고, 리소스 그룹은 앞서 생성한 "VPC01-Private-Instance", "VPC02-Private-Instance"를 선택합니다.

![](<.gitbook/assets/image (2).png>)

VPC01-Private-Instance, VPC02-Private-Instance를 각각 실행합니다.

모두 실행하고 나면, 아래와 같이 명령기록에 Shell이 8개 인스턴스에 모두 실행된 것을 확인할 수 있습니다.

![](<.gitbook/assets/image (62).png>)

### 15. ALB 구성

이제 N2SVPC에서 VPC01,VPC02의 인스턴스 로드밸런서를 위한 ALB 구성을 하고, Target Group을 각각 VPC01,02로 지정합니다.

**`EC2 Dashboard - Loadbalancer - Application Load Balancer`**를 선택합니다.

* **`Load balancer name : "ALB-VPC01-TG"`** 와 같은 이름을 입력합니다.
* **`scheme : "internet-facing"`** 를 선택합니다.

<figure><img src=".gitbook/assets/image (231).png" alt=""><figcaption></figcaption></figure>

* _**`VPC : N2SVPC`**_ 를 선택합니다.
* _**`Mappings : N2SVPC-Public-Subnet-A, B`**_ 를 선택합니다.

<figure><img src=".gitbook/assets/image (210).png" alt=""><figcaption></figcaption></figure>

* _**`Security groups : ALBSecurityGroup`**_ 을 선택합니다.

<figure><img src=".gitbook/assets/image (208).png" alt=""><figcaption></figcaption></figure>

Target Group이 만들어지지 않았습니다. Create target group을 새로운 창에 실행시킵니다.

<figure><img src=".gitbook/assets/image (203).png" alt=""><figcaption></figcaption></figure>

Target Group을 생성합니다.

* IP addresses 선택
* Target group name 생성 - VPC01-TG

<figure><img src=".gitbook/assets/image (221).png" alt=""><figcaption></figcaption></figure>

* _**`VPC 선택 - N2SVPC`**_
* _**`Health check path`**_

```
/ec2meta-webpage/index.php
```

<figure><img src=".gitbook/assets/image (217).png" alt=""><figcaption></figcaption></figure>

Target Group에 등록될 IP Address 를 구성합니다.

* Network : Other private IP address
* IPv4 address : 10.1.21.101 , 10.1.21.102 , 10.1.22.101, 10.1.22.102
* include as pending below 를 선택합니다.

<figure><img src=".gitbook/assets/image (212).png" alt=""><figcaption></figcaption></figure>

아래와 같이 IP 주소들이 입력되었는지 확인하고, _**`Create target group`**_ 을 선택합니다.

<figure><img src=".gitbook/assets/image (226).png" alt=""><figcaption></figcaption></figure>

다시 Loadbalancer 생성 메뉴를 확인합니다.

아래와 같이 _**`refresh`**_ 버튼을 누르고, _**`VPC01-TG`**_ 를 선택합니다.

<figure><img src=".gitbook/assets/image (204).png" alt=""><figcaption></figcaption></figure>

최종 구성을 확인하고, _**`create load balancer`**_ 를 생성합니다.



<figure><img src=".gitbook/assets/image (223).png" alt=""><figcaption></figcaption></figure>

정상적으로 ALB가 생성되었는 지 확인해 봅니다.

<figure><img src=".gitbook/assets/image (232).png" alt=""><figcaption></figcaption></figure>

Target Group의 IP 들이 Health Check가 정상적인지 확인합니다.

<figure><img src=".gitbook/assets/image (207).png" alt=""><figcaption></figcaption></figure>



### 16. ALB 트래픽 확인

아래에서 ALB의 내부 IP 주소를 확인해 봅니다.

**`AWS 관리콘솔 - EC2- 네트워크 및 보안 - 네트워크 인터페이스 - ALB-VPC01-TG`** 확인.

![](<.gitbook/assets/image (126).png>)

이제 다시 Cloud9 콘솔에서 앞서 실행 해 둔 Applicance 터미널에서 아래를 실행합니다.

```
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance1
sudo tcpdump -nvv 'port 6081' | grep '10.11.11.99'

```

```
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance2
sudo tcpdump -nvv 'port 6081' | grep '10.11.11.99'

```

여러분의 웹 브라우저에서 앞서 복사해둔 ALB DNS A Record와 나머지 URL을 입력합니다.

```
http://{ALB-DNS-A-Record}/ec2meta-webpage/index.php
```

![](<.gitbook/assets/image (192).png>)

&#x20;웹브라우저에서 ALB DNS A 레코드와 URL을 입력해서 실행시키면, GWLB에 연결해 둔 Appliance의 TCP Dump값에서 패킷을 통과하는 것을 확인 할 수 있습니다.

```
[ec2-user@ip-10-254-11-102 ~]$ sudo tcpdump -nvv 'port 6081' | grep '10.11.11.99'
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
    122.40.8.88.51754 > 10.11.11.99.http: Flags [S], cksum 0xdfa5 (correct), seq 1221545331, win 65535, options [mss 1460,nop,wscale 10,nop,nop,TS val 229789941 ecr 0,sackOK,eol], length 0
    122.40.8.88.51754 > 10.11.11.99.http: Flags [S], cksum 0xdfa5 (correct), seq 1221545331, win 65535, options [mss 1460,nop,wscale 10,nop,nop,TS val 229789941 ecr 0,sackOK,eol], length 0
    10.11.11.99.http > 122.40.8.88.51754: Flags [S.], cksum 0x7541 (correct), seq 3732648217, ack 1221545332, win 26847, options [mss 8645,sackOK,TS val 469191389 ecr 229789941,nop,wscale 8], length 0
    10.11.11.99.http > 122.40.8.88.51754: Flags [S.], cksum 0x7541 (correct), seq 3732648217, ack 1221545332, win 26847, options [mss 8645,sackOK,TS val 469191389 ecr 229789941,nop,wscale 8], length 0
    122.40.8.88.51754 > 10.11.11.99.http: Flags [.], cksum 0x2856 (correct), seq 1, ack 1, win 128, options [nop,nop,TS val 229789982 ecr 469191389], length 0
    122.40.8.88.51754 > 10.11.11.99.http: Flags [.], cksum 0x2856 (correct), seq 1, ack 1, win 128, options [nop,nop,TS val 229789982 ecr 469191389], length 0
    122.40.8.88.51754 > 10.11.11.99.http: Flags [P.], cksum 0xc6d2 (correct), seq 1:428, ack 1, win 128, options [nop,nop,TS val 229789982 ecr 469191389], length 427: HTTP, length: 427
    122.40.8.88.51754 > 10.11.11.99.http: Flags [P.], cksum 0xc6d2 (correct), seq 1:428, ack 1, win 128, options [nop,nop,TS val 229789982 ecr 469191389], length 427: HTTP, length: 427
    10.11.11.99.http > 122.40.8.88.51754: Flags [.], cksum 0x2693 (correct), seq 1, ack 428, win 110, options [nop,nop,TS val 469191431 ecr 229789982], length 0
    10.11.11.99.http > 122.40.8.88.51754: Flags [.], cksum 0x2693 (correct), seq 1, ack 428, win 110, options [nop,nop,TS val 469191431 ecr 229789982], length 0
    10.11.11.99.http > 122.40.8.88.51754: Flags [.], cksum 0x2a92 (correct), seq 1:1449, ack 428, win 110, options [nop,nop,TS val 469191516 ecr 229789982], length 1448: HTTP, length: 1448
    10.11.11.99.http > 122.40.8.88.51754: Flags [.], cksum 0x2a92 (correct), seq 1:1449, ack 428, win 110, options [nop,nop,TS val 469191516 ecr 229789982], length 1448: HTTP, length: 1448
    10.11.11.99.http > 122.40.8.88.51754: Flags [P.], cksum 0xda8c (correct), seq 1449:2777, ack 428, win 110, options [nop,nop,TS val 469191516 ecr 229789982], length 1328: HTTP
    10.11.11.99.http > 122.40.8.88.51754: Flags [P.], cksum 0xda8c (correct), seq 1449:2777, ack 428, win 110, options [nop,nop,TS val 469191516 ecr 229789982], length 1328: HTTP
```

VPC02의 인스턴스들과 ALB 로드밸런스도 위와 같은 방법으로 확인해 봅니다.

## 자원 삭제

로드 밸런서를 삭제 합니다. (**ALB-VPC01-TG, ALB-VPC02-TG 만 삭제합니다.**)

![](<.gitbook/assets/image (69).png>)

**`AWS 관리 콘솔 - 로드밸런싱 - 로드밸런서 - ALB-VPC01-TG, ALB-VPC02-TG 선택 - 작업 - 삭제`**&#x20;

ALB와 대상 그룹을 삭제합니다. (**VPC01-TG,VPC02-TG 만 삭제 합니다.**)

* **`EC2 - 로드밸런싱 - 대상 그룹 - VPC01-TG 선택 - 작업 선택 - 삭제`**
* **`EC2 - 로드밸런싱 - 대상 그룹 - VPC02-TG 선택 - 작업 선택 - 삭제`**

**`AWS 관리콘솔 - Cloudformation - 스택`** 을 선택하고 생성된 Stack을 삭제합니다.

GWLBTGW,VPC01,VPC02,N2SVPC,GWLBVPC 순으로 삭제합니다.(Cloud9은 계속 사용하기 위해 삭제 하지 않습니다.)

1. GWLBTGW를 삭제합니다. (3\~4분 소요됩니다.)
2. VPC01,VPC02를 삭제합니다. (3\~4분 소요됩니다. 동시 진행합니다.)
3. N2SVPC를 삭제 합니다. (3\~4분 소요됩니다.)
4. GWLBVPC를 삭제 합니다. (3\~4분 소요됩니다.)

```
aws cloudformation delete-stack --stack-name GWLBTGW
aws cloudformation delete-stack --stack-name VPC01
aws cloudformation delete-stack --stack-name VPC02
aws cloudformation delete-stack --stack-name N2SVPC
aws cloudformation delete-stack --stack-name GWLBVPC
```

![](https://github.com/whchoi98/aws-gwlb/raw/master/.gitbook/assets/image%20\(85\).png)

랩을 완전히 종료하려면 **`AWS 관리콘솔 - Cloudformation - 스택`** aws cloud9 콘솔 스택도 삭제합니다.
