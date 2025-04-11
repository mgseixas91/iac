# IaC - Infrastructure as Code com Terraform

##  **Visão Geral**
Este repositório contém a infraestrutura definida como código (IaC) utilizando o Terraform para provisionamento de recursos em AWS, como EKS, ECR, S3 e KMS.

---

##  **Estrutura de Diretórios**
```bash
iac/
├── ecr/
│   ├── app1/
│   │   ├── backend.tf
│   │   ├── ecr.tf
│   │   ├── provider.tf
│   │   └── variables.tf
│   └── app2/
│       ├── backend.tf
│       ├── ecr.tf
│       ├── provider.tf
│       └── variables.tf
├── kms/
│   ├── backend.tf
│   └── kms.tf
├── s3/
│   ├── backend.tf
│   ├── providers.tf
│   ├── s3.tf
│   └── variables.tf
└── eks/
    ├── backend.tf
    ├── eks.tf
    ├── outputs.tf
    ├── providers.tf
    ├── variables.tf
    └── addons/
        ├── nginx-controller/
        │   └── values.yaml
        ├── cloudwatch-agent/
        │   ├── deployment.yaml
        │   ├── configmap.yaml
        │   └── namespace.yaml
        └── cluster-autoscaler/
            └── values.yaml
```

---

## **Pré-requisitos**

### Terraform
É necessário possuir o Terraform instalado. Para Ubuntu:
```bash
sudo apt update && sudo apt install -y gnupg software-properties-common curl
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### Bucket S3
Antes de rodar qualquer módulo, é necessário ter um bucket S3 para armazenar o state remoto do Terraform.

### ECR
Utilizado para armazenar as imagens Docker das aplicações `app1` e `app2`. Pré-requisito para implantação das aplicações em containers.

### KMS
Utilizado para criptografar secrets sensíveis no cluster EKS (como configurações do Secrets Manager ou K8s secrets).

---

## **Padrão dos Arquivos Terraform**
- `backend.tf`: configuração do state remoto (normalmente apontando para um bucket S3).
- `provider.tf`: define os providers utilizados e suas versões.
- `*.tf` (ex: `ecr.tf`, `s3.tf`, `kms.tf`): contêm os recursos a serem criados.
- `variables.tf`: define variáveis para reutilização e parametrização.

### Provider do Terraform
Utilizei a versão `5.20.0` do provider AWS, pois essa versão oferece suporte mais robusto a recursos de autenticação (como IRSA) e melhorias no controle de estado e dependências de recursos.

---

## **Sobre o Módulo `eks.tf`**

- **data "aws_caller_identity"**: captura dados da conta atual para uso em configurações.
- **locals**: definição de tags e recursos fixos (como VPC e Subnets).
- **module "eks"**: cria o cluster EKS com configurações de versão, log, segurança, nodegroups e tags.
- **cluster_addons**: instala o `coredns`, `kube-proxy` e `vpc-cni` (com IRSA).
- **security_group_additional_rules**: regras para comunicação entre nodes e cluster.
- **eks_managed_node_groups**: cria o nodegroup com instâncias `t3.micro`.
- **auth configmap**: está gerenciado via Terraform, mas não foi adicionado nenhum usuário.
- **IRSA habilitado**: integra roles do IAM a service accounts no K8s. - Solicitado no documento.

### Módulos de suporte
- **cluster_autoscaler_irsa**: cria a role necessária para o Cluster Autoscaler funcionar com IRSA.
- **vpc_cni_irsa**: cria a role necessária para o VPC CNI.

> Obs: Nenhum usuário foi adicionado ao `aws_auth_users`, pois o cluster foi criado com credenciais root. Para adicionar, crie um IAM user com a role `AmazonEKSClusterAdminPolicy` e insira no `aws_auth_users`.

---

## 🛠️ **Addons**

### Nginx Ingress Controller
Utilizado no lugar do Traefik por ser mais amplamente suportado, bem documentado e com maior comunidade. É ideal para ambientes de produção com granularidade fina em configurações de roteamento.

Instalado via Helm:
```bash
# helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
# helm repo update
# helm upgrade --install nginx-private \
  ingress-nginx/ingress-nginx \
  --namespace nginx-controller \
  -f values.yaml \
  --create-namespace
```

### Cloudwatch Agent
Não foi instalado devido a custos. Os manifests estão disponíveis para instalação futura.

### Cluster Autoscaler
Embora não tenha sido aplicado, o `.yaml` de instalação está presente. A escalabilidade foi configurada diretamente via `eks_managed_node_groups` no Terraform.

---

## **Comandos Terraform mais usados**
```bash
terraform init       # Inicializa os plugins e configurações
terraform plan       # Exibe as mudanças antes de aplicar
terraform apply      # Aplica as mudanças
terraform destroy    # Destroi todos os recursos gerenciados
```




---
