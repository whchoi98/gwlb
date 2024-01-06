---
description: 'Update : 2022-06-12/ 1h /Cloudformation CLI 배포로 변경'
---

# GWLB Design 2

## 목표 구성 개요

3개의 각 워크로드 VPC (VPC01,02,03)은 Account내에 구성된 GWLB 기반의 보안 VPC를 통해서 내, 외부 트래픽을 처리하는 구성입니다. GWLB 기반의 보안 VPC는 2개의 AZ에 4개의 가상 Appliance가 로드밸런싱을 통해 처리 됩니다.

이러한 구성은 VPC Endpoint를 특정 VPC에 구성하고, TransitGateway를 통해 GWLB에 VPC Endpoint Service를 연결하는 중앙집중 구조입니다.

아래 그림은 목표 구성도 입니다.

#### :clapper: 아래 동영상 링크에서 구성방법을 확인 할 수 있습니다.

{% embed url="https://youtu.be/ZyxN2fOiw9A" %}

![](<.gitbook/assets/image (27).png>)

## Cloudformation기반 VPC 배포

### 1.VPC yaml 파일 다운로드

Cloud9 콘솔에서 아래 github로 부터 VPC yaml 파일을 다운로드 합니다. (앞서 다운로드 하였으면 생략합니다.)

```
git clone https://github.com/whchoi98/gwlb.git

```

아래와 같은 순서로 Cloudformation에서 Yaml파일을 배포합니다.&#x20;

1. GWLBVPC.yml
2. N2SVPC.yml
3. VPC01.yml, VPC02.yml
4. GWLBTGW.yml

{% hint style="danger" %}
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
* KeyPair : 사전에 만들어 둔 keyPair를 사용합니다. (예. gwlbkey)



3\~4분 후에 GWLBVPC가 완성됩니다.

**`AWS 관리콘솔 - VPC - 가상 프라이빗 클라우드 - 엔드포인트 서비스`** 를 선택합니다. Cloudformation을 통해서 VPC Endpoint 서비스가 이미 생성되어 있습니다. 이것을 선택하고 **`세부 정보`**를 확인합니다.

VPC Endpoint Service Name을 복사해 둡니다. 뒤에서 생성할 VPC들의 Cloudformation에서 사용할 것입니다.

![](<.gitbook/assets/image (47).png>)

VPCEndpointServiceName 값을 아래에서 처럼 환경변수에 저장해 둡니다. &#x20;

```
export VPCEndpointServiceName2=$(aws ec2 describe-vpc-endpoint-services --filter "Name=service-type,Values=GatewayLoadBalancer" | jq -r '.ServiceNames[]')
echo $VPCEndpointServiceName2
echo "export VPCEndpointServiceName1=${VPCEndpointServiceName2}" | tee -a ~/.bash_profile
source ~/.bash_profile

```

### 3.N2SVPC 배포&#x20;

외부 인터넷으로 통신하는 North-South 트래픽 처리를 하는 VPC를 생성합니다.

N2SVPC를 Cloudformation에서 앞서 과정과 동일하게 생성합니다. 다운로드 받은 Yaml 파일들 중에 N2SVPC 선택해서 생성합니다.스택 이름을 생성하고, GWLBVPC의 VPC Endpoint 서비스 이름을 **`"VPCEndpointServiceName"`** 에 입력합니다. 또한 나머지 파라미터들도 입력합니다. 대부분 기본값을 사용합니다.

* 스택이름 : N2SVPC
* AvailabilityZone A : ap-northeast-2a
* AvailabilityZone B : ap-northeast-2b
* VPCCIDRBlock: 10.11.0.0
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
* KeyPair : 사전에 만들어 둔 keyPair를 사용합니다.(예. gwlbkey)

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "N2SVPC" \
  --template-file "/home/ec2-user/environment/gwlb/Case2/2.Case2-N2SVPC.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
    "VPCEndpointServiceName2=$VPCEndpointServiceName2" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

### 4.VPC01,02 배포 &#x20;

#### 나머지 VPC01,VPC02,VPC03 의 Cloudformation Yaml 파일을 업로드 합니다.

{% hint style="warning" %}
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
  --template-file "/home/ec2-user/environment/gwlb/Case2/3.Case2-VPC01.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "VPC02" \
  --template-file "/home/ec2-user/environment/gwlb/Case2/3.Case2-VPC02.yml" \
  --parameter-overrides \
    "KeyPair=$KeyName" \
  --capabilities CAPABILITY_NAMED_IAM
  
```

N2SVPC, VPC01,02,03 을 연결할 TGW를 생성합니다.  N2STGW는 TGW Routing Table과 각 VPC들이 Route Table을 자동으로 구성해 줍니다.

* Stack Name : GWLBTGW
* DefaultRouteBlock: 0.0.0.0/0
* VPC01CIDRBlock: 10.1.0.0/16
* VPC02CIDRBlock: 10.2.0.0/16

```
aws cloudformation deploy \
  --region ap-northeast-2 \
  --stack-name "GWLBTGW" \
  --template-file "/home/ec2-user/environment/gwlb/Case2/4.Case2-GWLBTGW.yml" 
  
```

**`AWS 관리 콘솔 - VPC 대시 보드 - VPC`**

![](<.gitbook/assets/image (19).png>)

**`AWS 관리 콘솔 - VPC 대시 보드 - 서브넷`**

![](<.gitbook/assets/image (187).png>)

### 5. TransitGateway 배포&#x20;

N2SVPC, VPC01,VPC02을 연결하기 위한 TransitGateway를 배포합니다. 앞서 git을 통해 다운 받은 파일 중 GWLBTGW.yml 파일을 Cloudformation을 통해서 배포합니다.

![](<.gitbook/assets/image (42).png>)

**`Default Route Table`**과 **`VPC01, VPC02 CIDR`** 주소를 입력합니다. (기본 값으로 설정되어 있습니다.)

![](<.gitbook/assets/image (60).png>)

### 6. 라우팅 테이블 확인 &#x20;

TransitGateway 구성과 RouteTable을 아래에서 확인합니다.&#x20;

![](<.gitbook/assets/image (168).png>)

**`AWS 관리 콘솔 - VPC 대시보드 - TransitGateway`** 에서 TransitGateway가 정상적으로 구성되었는지 확인합니다.

![](<.gitbook/assets/image (6).png>)

**`AWS 관리 콘솔 - VPC 대시보드 - TransitGateway- TransitGateway 연결(Attachment)`** 에서 TransitGateway와 VPC가 정상적으로 연결되었는지 확인합니다.

![](<.gitbook/assets/image (145).png>)

**`AWS 관리콘솔 - VPC 대시보드 -TransitGateway-TransitGateway 라우팅 테이블-Route`** 에서 **`"GWLBTGW-RT-VPC-OUT, "GWLBTGW-RT-VPC-IN"`** 라우팅 테이블을 확인합니다.

* GWLBTGW-RT-VPC-OUT : VPC01,VPC02 에서 인터넷으로 향하는 트래픽
* GWLBTGW-RT-VPC-IN: VPC01,VPC02 로 내부로 향하는 트래픽

![](<.gitbook/assets/image (49).png>)

![](<.gitbook/assets/image (11).png>)

**`AWS 관리 콘솔 -VPC 대시보드 - 가상 프라이빗 클라우드 - 라우팅테이블`**에서  각 Private-Subnet-A,B-RT 라우팅 테이블을 확인합니다.&#x20;

* VPC01,02-Private-Subnet-A,B-RT  : 0.0.0.0/0 - tgw&#x20;

![](<.gitbook/assets/image (198).png>)

## GWLB 구성 확인

GWLBVPC 구성을 확인해 봅니다.

1. GWLB 구성
2. GWLB Target Group 구성
3. VPC Endpoint 와 Service 확인
4. Appliance 확인&#x20;

![](<.gitbook/assets/image (64).png>)

### 7.GWLB 구성&#x20;

**`AWS 관리 콘솔 - EC2 - 로드밸런싱 - 로드밸런서`** 메뉴를 선택합니다. Gateway LoadBalancer 구성을 확인할 수 있습니다. ELB 유형이 **`"gateway"`**로 구성된 것을 확인 할 수 있습니다.

![](<.gitbook/assets/image (12).png>)

### 8.GWLB Target Group 구성&#x20;

**`AWS 관리 콘솔 - EC2 - 로드밸런싱 - 대상 그룹`**을 선택합니다. GWLB가 로드밸런싱을 하게 되는 대상그룹(Target Group)을 확인 할 수 있습니다.

* &#x20;프로토콜 : **`GENEVE 6081`** (포트 6081의 GENGEVE 프로토콜을 사용하여 모든 IP 패킷을 수신하고 리스너 규칙에 지정된 대상 그룹에 트래픽을 전달합니다.)
* 등록된 대상 : GWLB가 로드밸런싱을 하고 있는 Target 장비를 확인합니다.

![](<.gitbook/assets/image (139).png>)

**`AWS 관리 콘솔 - EC2 - 로드밸런싱 - 대상 그룹 - 상태검사`** 메뉴를 확인합니다.

ELB와 동일하게 대상그룹(Target Group)에 상태를 검사할 수 있습니다. 이 랩에서는 HTTP  Path / 를 통해서 **`Health Check`**를 하도록 구성했습니다.

![](<.gitbook/assets/image (191).png>)

### 9. VPC Endpoint Service 확인

N2SVPC Private link로 연결하기 위해, GWLB VPC에 Endpoint Service를 구성하였습니다. 이를 확인해 봅니다.

**`AWS 관리 콘솔 - VPC - 엔드포인트 서비스`**를 선택합니다. 생성된 VPC Endpoint Service를 확인할 수 있습니다.

* 서비스 이름 - 예 com.amazonaws.vpce.ap-northeast-2.vpce-svc-082d152b9180f8ad0
* 유형 : GatewayLoadBalancer
* 가용영역 : ap-northeast-2a, ap-northeast-2b

2개 영역에 걸쳐서 GWLB에 대해 VPC Endpoint Service를 구성하고 있습니다.

![](<.gitbook/assets/image (216).png>)

**`AWS 관리 콘솔 - VPC - 엔드포인트 서비스-엔드포인트 연결`**를 선택합니다.

N2SVPC의 각 가용영역들과 연결된 것을 확인 할 수 있습니다. VPC별 2개의 가용영역의 Private Subnet에 배치된 VPC Endpoint에 연결된 것을 확인 합니다.

![](<.gitbook/assets/image (185).png>)

### 10. Appliance 확인&#x20;

**`AWS 관리 콘솔 - EC2 - 인스턴스`** 메뉴를 선택하고, "appliance" 키워드로 필터링 해 봅니다. 4개의 리눅스 기반의 appliance가 설치되어 있습니다.

![](<.gitbook/assets/image (140).png>)

Appliance 구성 정보를 확인해 봅니다.

**`AWS 관리콘솔 - Cloudformation - 스택`**을 선택하면, 앞서 배포했던 Cloudformation 스택들을 확인 할 수 있습니다. **`"GWLBVPC"`**를 선택합니다. 그리고 출력을 선택합니다. 값을 확인해 보면 공인 IP 주소를 확인 할 수 있습니다.

![](<.gitbook/assets/image (21).png>)

앞서 사전 준비에서 생성한 Cloud9  터미널에서 Appliance로 직접 접속해 봅니다.

```
export Appliance2_1={Appliance1ip address}
export Appliance2_2={Appliance2ip address}
export Appliance2_3={Appliance3ip address}
export Appliance2_4={Appliance4ip address}
```

아래와 같이 구성합니다.

```
#기존 Appliance 정보를 삭제
sudo sed '/Appliance/d' ~/.bash_profile

#Appliance IP Export
export Appliance2_1=3.36.108.211
export Appliance2_2=52.79.219.13
export Appliance2_3=13.125.201.96
export Appliance2_4=15.164.176.82

#bash profile에 등록
echo "export Appliance2_1=$Appliance2_1" | tee -a ~/.bash_profile
echo "export Appliance2_2=$Appliance2_2" | tee -a ~/.bash_profile
echo "export Appliance2_3=$Appliance2_3" | tee -a ~/.bash_profile
echo "export Appliance2_4=$Appliance2_4" | tee -a ~/.bash_profile
source ~/.bash_profile

```

각 Appliance에서 아래 명령을 통해 , GWLB IP와 어떻게 매핑되었는지 확인합니다. Cloud9에서 새로운 터미널 4개를 탭에서 추가해서 4개 Appliance를 모두 확인해 봅니다.

```
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance1
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance2
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance3
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance4

```

각 Appliance에서 아래 명령을 통해 , GWLB IP와 어떻게 매핑되었는지 확인합니다.&#x20;

```
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance1
sudo iptables -L -n -v -t nat
```

AZ A에 배포된 Appliance는 다음과 같이 출력됩니다.

```
[ec2-user@ip-10-254-11-101 ~]$ sudo iptables -L -n -v -t nat
Chain PREROUTING (policy ACCEPT 3417 packets, 204K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  351 45728 DNAT       udp  --  eth0   *       10.254.11.107        10.254.11.101        to:10.254.11.107:6081

Chain INPUT (policy ACCEPT 3417 packets, 204K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 981 packets, 75316 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 981 packets, 75316 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  351 45728 MASQUERADE  udp  --  *      eth0    10.254.11.107        10.254.11.107        udp dpt:6081
```

GENEVE 터널링의 GWLB IP주소는 10.254.11.60  이며, Appliance IP와 터널링 된 것을 확인 할 수 있습니다.

AZ B에 배포된 Appliance는 다음과 같이 출력됩니다.

```
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance3
sudo iptables -L -n -v -t nat

```

```
[ec2-user@ip-10-254-12-101 ~]$ sudo iptables -L -n -v -t nat
Chain PREROUTING (policy ACCEPT 3765 packets, 225K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  353 45872 DNAT       udp  --  eth0   *       10.254.12.28         10.254.12.101        to:10.254.12.28:6081

Chain INPUT (policy ACCEPT 3765 packets, 225K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 1693 packets, 136K bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain POSTROUTING (policy ACCEPT 1693 packets, 136K bytes)
 pkts bytes target     prot opt in     out     source               destination         
  353 45872 MASQUERADE  udp  --  *      eth0    10.254.12.28         10.254.12.28         udp dpt:6081
```

GENEVE 터널링의 GWLB IP주소는 10.254.12.101  이며, Appliance IP와 터널링 된 것을 확인 할 수 있습니다.

이렇게 GWLB 에서 생성된 IP주소와 각 Appliance의 IP간에 UDP 6081 포트로 터널링되어 , 외부의 IP 주소와 내부의 IP 주소를 그대로 유지할 수 있습니다. 또한 터널링으로 인입시 5Tuple (출발지 IP, Port, 목적지 IP, Port, 프로토콜)의 정보를 TLV로 Encapsulation하여 분산처리할 때 사용합니다.

## 외부 연결용 VPC 확인

이제 외부 연결 VPC에서 실제 구성과 트래픽을 확인해 봅니다.

1. VPC Endpoint 확인
2. Private Subnet Route Table 확인
3. Ingress Routing Table 확인



아래 흐름과 같이 트래픽이 처리됩니다.

![](<.gitbook/assets/image (186).png>)

1. VPC1,2 인스턴스는 외부로 향하기 위해 TransitGateway로 접근
2. VPC 1,2 Private Subnet Route Table을 참조해서, Transit Gateway로 전
3. TransitGateway Routing Table을 참조해서, N2SVPC Attachment로 전
4. N2SVPC 로 인입된 트래픽은 N2SVPC TGW Routing Table에 의해 VPC Endpoint로 전달.
5. VPC Endpoint는 GWLBVPC Private Link의 VPC Endpoint Service로 전달하고, VPC EndpointService는 GWLB로 트래픽 전달.
6. AZ A,AZ B Target Group으로 LB 처리 - UDP 6081 GENEVE로 Encapsulation (TLV Header - 5Tuple)
7. Appliance에서 트래픽 처리 후 다시 Return
8. Decap 해서 다시 VPC Endpoint Service로 전달하고, N2SVPC VPC Endpoint로 전달
9. Private Subnet Route Table에서 Public Subnet의 NAT Gateway로 트래픽 전달하고, 외부로 전송.

### 11.VPC Endpoint 확인

**`AWS 관리 콘솔 - VPC - Endpoint`**를 선택하여 실제 구성된 VPC Endpoint를 확인해 봅니다. N2SVPC에 2개씩 구성된 AZ를 위해 2개의 Endpoint가 구성되어 있습니다. (VPC Endpoint는 AZ Subnet당 연결됩니다.)

![](<.gitbook/assets/image (138).png>)

### 12. N2S VPC Route Table 확인

AWS 관리콘솔 - VPC - 라우팅 테이블을 선택하고 각 라우팅 테이블을 확인해 봅니다.&#x20;

![](<.gitbook/assets/image (18).png>)

**`AWS 관리 콘솔 - VPC 대시보드 - 라우팅 테이블 - N2SVPC TGW Routing Table`** 확인&#x20;

![](<.gitbook/assets/image (15).png>)

**`AWS 관리 콘솔 - VPC 대시보드 - 라우팅 테이블 - N2SVPC Private Routing Table`** 확인

![](<.gitbook/assets/image (36).png>)

**`AWS 관리 콘솔 - VPC 대시보드 - 라우팅 테이블 - N2SVPC Public Routing Table`** 확인

![](<.gitbook/assets/image (38).png>)

## 트래픽 확인

### 13. Workload VPC의 EC2에서 트래픽 확인&#x20;

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

![](<.gitbook/assets/image (125).png>)

**`AWS 관리콘솔 - EC2 대시보드 - 인스턴스`** 에서 VPC1,2 인스턴스를 선택하고 IAM Profile이 정상적으로 구성되었는지 확인합니다.

![](<.gitbook/assets/image (127).png>)

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
whchoi:~/environment/useful-shell (master) $ ./aws_ec2_ext.sh 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
|                                                                                     DescribeInstances                                                                                    |
+----------------------------------------------------------+------------------+----------------------+-------------+------------------------+----------+----------------+------------------+
|  GWLBVPC-Appliance-10.254.12.101                         |  ap-northeast-2b |  i-0a6b2480d00cc4f2e |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.254.12.101 |  13.125.201.96   |
|  VPC01-Private-B-10.1.22.101                             |  ap-northeast-2b |  i-0e18cd39adc506152 |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.1.22.101   |  15.165.71.140   |
|  VPC02-Private-B-10.2.22.102                             |  ap-northeast-2b |  i-0c845727d893497e0 |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.2.22.102   |  3.35.36.160     |
|  VPC01-Private-B-10.1.22.102                             |  ap-northeast-2b |  i-0158f77d3d82bc5c5 |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.1.22.102   |  3.36.16.73      |
|  GWLBVPC-Appliance-10.254.12.102                         |  ap-northeast-2b |  i-034b96ea088fff702 |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.254.12.102 |  15.164.176.82   |
|  VPC02-Private-B-10.2.22.101                             |  ap-northeast-2b |  i-0bdf1041a2e96821b |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.2.22.101   |  15.164.175.224  |
|  aws-cloud9-gwlbconsole-48d6905e23ce4b4caa4485af333c10d2 |  ap-northeast-2a |  i-0de0bd7634580007f |  m5.2xlarge |  ami-011f8bfe22440499a |  running |  172.31.15.73  |  3.34.138.122    |
|  GWLBVPC-Appliance-10.254.11.102                         |  ap-northeast-2a |  i-09cbcb92c6d56ba4f |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.254.11.102 |  52.79.219.13    |
|  GWLBVPC-Appliance-10.254.11.101                         |  ap-northeast-2a |  i-0392b05b26d86c2fb |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.254.11.101 |  3.36.108.211    |
|  VPC02-Private-A-10.2.21.102                             |  ap-northeast-2a |  i-0b13d38867d6478ac |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.2.21.102   |  52.78.103.50    |
|  VPC02-Private-A-10.2.21.101                             |  ap-northeast-2a |  i-0432ad8f68349c144 |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.2.21.101   |  13.209.18.196   |
|  VPC01-Private-A-10.1.21.101                             |  ap-northeast-2a |  i-014b816ced3052e9f |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.1.21.101   |  13.125.81.136   |
|  VPC01-Private-A-10.1.21.102                             |  ap-northeast-2a |  i-04cec9252330cce2b |  t3.small   |  ami-07464b2b9929898f8 |  running |  10.1.21.102   |  3.36.116.245    |
+----------------------------------------------------------+------------------+----------------------+-------------+------------------------+----------+----------------+------------------+
```

session manager 명령을 통해 해당 인스턴스에 연결해 봅니다. (예. VPC01-Private-A-10.1.21.101)

```
aws ssm start-session --target {VPC01-Private-A-10.1.21.101 Instance ID}

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
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance1
sudo tcpdump -nvv 'port 6081' | grep 'ICMP'

```

Cloud9 터미널 2

```
ssh -i ~/environment/gwlbkey.pem ec2-user@$Appliance2
sudo tcpdump -nvv 'port 6081' | grep 'ICMP'

```

다음과 같이 1개의 터미널에서 icmp가 처리되는 것을 확인 할 수 있습니다.

```
[ec2-user@ip-10-254-11-102 ~]$ sudo tcpdump -nvv 'port 6081'
tcpdump: listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
15:12:15.788834 IP (tos 0x0, ttl 255, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.107.60000 > 10.254.11.102.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data f583215d 2e66b39c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 6742cc6d]
        IP (tos 0x0, ttl 253, id 62598, offset 0, flags [DF], proto ICMP (1), length 84)
    10.1.21.101 > 99.86.206.123: ICMP echo request, id 32496, seq 4971, length 64
15:12:15.788867 IP (tos 0x0, ttl 254, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.102.60000 > 10.254.11.107.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data f583215d 2e66b39c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 6742cc6d]
        IP (tos 0x0, ttl 253, id 62598, offset 0, flags [DF], proto ICMP (1), length 84)
    10.1.21.101 > 99.86.206.123: ICMP echo request, id 32496, seq 4971, length 64
15:12:15.790832 IP (tos 0x0, ttl 255, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.107.60000 > 10.254.11.102.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data f583215d 2e66b39c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 6742cc6d]
        IP (tos 0x0, ttl 237, id 27319, offset 0, flags [none], proto ICMP (1), length 84)
    99.86.206.123 > 10.1.21.101: ICMP echo reply, id 32496, seq 4971, length 64
15:12:15.790847 IP (tos 0x0, ttl 254, id 0, offset 0, flags [none], proto UDP (17), length 152)
    10.254.11.102.60000 > 10.254.11.107.6081: [udp sum ok] Geneve, Flags [none], vni 0x0, options [class Unknown (0x108) type 0x1 len 12 data f583215d 2e66b39c, class Unknown (0x108) type 0x2 len 12 data 00000000 00000000, class Unknown (0x108) type 0x3 len 8 data 6742cc6d]
        IP (tos 0x0, ttl 237, id 27319, offset 0, flags [none], proto ICMP (1), length 84)
    99.86.206.123 > 10.1.21.101: ICMP echo reply, id 32496, seq 4971, length 64

```

Source IP와 Destination IP가 모두 유지된 채로 통신하는 것을 확인 할 수 있습니다.

이제 다른 VPC(VPC01,VPC02)와 다른 서브넷의 EC2에서도 트래픽이 정상적으로 처리되는지 확인해 봅니다.

## 자원 삭제

**`AWS 관리콘솔 - Cloudformation - 스택`** 을 선택하고 생성된 Stack을 삭제합니다.

GWLBTGW,VPC01,VPC02,N2SVPC,GWLBVPC 순으로 삭제합니다.(Cloud9은 계속 사용하기 위해 삭제 하지 않습니다.)&#x20;

1. GWLBTGW를 삭제합니다. (3\~4분 소요됩니다.)
2. VPC01,VPC02를 삭제합니다. (3\~4분 소요됩니다. 동시 진행합니다.)
3. N2SVPC를 삭제 합니다. (3\~4분 소요됩니다.)
4. GWLBVPC를 삭제 합니다. (3\~4분 소요됩니다.)

```
#GWLBTGW를 삭제합니다. (3~4분 소요됩니다.)
aws cloudformation delete-stack --stack-name GWLBTGW
#VPC01,VPC02,N2SVPC를 삭제합니다. (3~4분 소요됩니다. 동시 진행합니다.)
aws cloudformation delete-stack --stack-name VPC01
aws cloudformation delete-stack --stack-name VPC02
aws cloudformation delete-stack --stack-name N2SVPC
#GWLBVPC를 삭제 합니다. (3~4분 소요됩니다.)
aws cloudformation delete-stack --stack-name GWLBVPC
```

![](<.gitbook/assets/image (155).png>)

랩을 완전히 종료하려면 **`AWS 관리콘솔 - Cloudformation - 스택`**  aws cloud9 콘솔 스택도 삭제합니다.
