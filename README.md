# Automação de Infraestrutura AWS com Terraform e Ansible

Este repositório contém um projeto completo de **Infrastructure as Code (IaC)** para provisionar e configurar uma arquitetura de aplicação web multi-camada na AWS. A automação é feita usando:

1.  **Terraform** para construir a fundação da rede (VPC, subnets, gateways), provisionar 5 instâncias EC2, chaves, grupos de segurança e o serviço de Cache ElastiCache (Redis).

2.  **Ansible** para configurar as instâncias, implantar as aplicações (via Docker), configurar o banco de dados (MySQL), configurar o balanceador de carga (Nginx) e configurar o broker de mensagens (RabbitMQ).

---
## 🏗️ Arquitetura da Aplicação (Com Cache e Fila de Mensagens)

A infraestrutura provisionada pelo Terraform e configurada pelo Ansible, sendo dividida em quatro camadas principais:

### 1. Rede (VPC)
* Uma **VPC** (`10.0.0.0/24`) dividida em:
    * **Subnet Pública:** Com um Internet Gateway (IGW) para acesso externo.
    * **Subnet Privada:** Com um NAT Gateway para permitir que os serviços internos acessem a internet sem serem expostos.

### 2. Segurança (Security Groups)
* **`web` (Bastion/Nginx):** Permite tráfego público (HTTP/HTTPS/SSH).
* **`app` (Aplicações):** Permite tráfego apenas do SG `web` (nas portas da aplicação) e SSH (vindo do bastion).
* **`db` (Banco de Dados):** Permite tráfego apenas do SG `app` (porta MySQL) e SSH (vindo do bastion).

### 3. Servidores (Instâncias EC2)
* **`web-server-01` (Subnet Pública):** Atua como Bastion Host e Proxy Reverso/Load Balancer (Nginx).
* **`app-server-01` e `\app-server-02` (Subnet Privada):** Rodam a aplicação principal via Docker e se conectam ao DB e ao Redis.
* **`chatbot-server` (Subnet Privada):** Roda a aplicação do chatbot via Docker, e hospeda o container RabbitMQ (broker de mensagens).
* **`db-server-01` (Subnet Privada):** Roda o banco de dados MySQL.

### 4. Serviços Gerenciados (ElastiCache)
* **ElastiCache (Redis):** Um cluster Redis na Subnet Privada para cache da aplicação Eleve, com criptografia em trânsito e autenticação (auth_token).
---

## 📋 Pré-requisitos

Antes de iniciar, você precisará de:

* **WSL** (caso esteja usando Windows)
* **AWS CLI**
* **Terraform**
* **Ansible**
---

## ⚙️ Configuração

Siga estes passos para configurar o seu ambiente.

### 1. Configuração do Terraform

#### 1.1 Configurar Credenciais da AWS CLI

- Obtenha sua **Access Key ID**, **Secret Access Key** e **Session Token** (caso seja uma conta de estudante).

- Execute o comando no seu terminal:
    ```bash
    aws configure
    ```

- Preencha os prompts na seguinte ordem:

    ```
    AWS Access Key ID [None]: SUA_ACCESS_KEY
    AWS Secret Access Key [None]: SUA_SECRET_KEY
    AWS Session Token [None]: SUA_SESSION_TOKEN
    Default region name [None]: us-east-1
    Default output format [None]: json
    ```

#### 1.2 Configurar Variáveis Sensíveis
- Edite o arquivo /Terraform/terraform.tfvars e defina a senha do Redis:
    ```hcl
    redis_password = "sua_senha_do_redis"
    ```
---

### 2. Configuração do Ansible

### 2.1 Inventário e Variáveis

O Terraform agora gera automaticamente os arquivos inventory.ini e vars.yml ao ser executado.
- inventory.ini: Contém os IPs de todas as instâncias.
- vars.yml: Contém o endereço do cluster ElastiCache (Redis) para uso nas aplicações.
---

## 🚀 Como Executar

### Terraform

Abra um terminal dentro da pasta ``/Terraform`` e execute o seguinte comando:
```bash
terraform init
terraform apply
# Em seguida digite 'yes'
```
Ao fim da execução, o Terraform preencherá os arquivos inventory.ini e vars.yml automaticamente.
---

### Ansible

 Caso esteja no Windows o uso do **WSL é obrigatório!**

Execute os seguintes comandos dentro do WSL:

```bash
# Substitua os placeholders SEU_USUARIO e CAMINHO_DO_REPOSITORIO
sudo cp -r "/mnt/c/Users/SEU_USUARIO/CAMINHO_DO_REPOSITORIO/Infra-Backup" ~/
cd ~/Infra-Backup
```

---

#### 1. Configurar Permissões da Chave SSH

O SSH e o Ansible são muito rigorosos quanto às permissões da chave.

```bash
sudo chown $USER:$USER AWSKey.pem
chmod 600 ./AWSKey.pem
```

#### 2. Adicionar Chave ao SSH Agent

Isso permite que o Ansible use a chave para o ProxyJump (conexão bastion) sem pedir a senha da chave.

```bash
eval $(ssh-agent -s)
ssh-add ./AWSKey.pem
```

#### 3. Testar a Conexão

Antes de rodar o playbook, verifique se você consegue acessar uma máquina privada através do bastion.

```bash
# Use os IPs do seu inventory.ini
ssh -J ubuntu@IP_PUBLICO ubuntu@IP_PRIVADO
# Digite 'yes' duas vezes
```

Se a conexão for bem-sucedida, você pode sair digitando ``exit`` e prosseguir.

#### 4. Executar o Playbook Ansible

Você precisará fornecer a senha do vault.

```bash
ansible-playbook playbook.yml --ask-vault-pass
# Em seguida digite a senha do vault
```
Ao fim da execução, teste sua conexão acessando ``http://IP_PUBLICO`` no seu navegador.

---

## 📂 Estrutura do Repositório

```ini
C:.
│   ansible.cfg       # Configurações do Ansible
│   inventory.ini     # (GERADO AUTOMATICAMENTE) Inventário de hosts (servidores)
│   inventory.ini.tpl # Template para geração do inventory.ini
│   nginx.conf.j2     # Template Jinja2 para a configuração do Nginx
│   playbook.yml      # O playbook principal que orquestra tudo
│   README.md         # Este arquivo
│   secrets.yml       # (CRIPTOGRAFADO) Variáveis sensíveis (DB, RabbitMQ, Chaves API)
│   vars.yml          # (GERADO AUTOMATICAMENTE) Endpoint do Redis/ElastiCache
│
├───Terraform
│       eleve.tf      # Script para provisionamento da infra
│       terraform.tfvars # (ADICIONADO) Arquivo para variáveis sensíveis (redis_password)
│
├───Backend
│       eleve.jar     # Artefato da aplicação "Eleve"
│
├───Chatbot
│       chatbot.jar   # Artefato da aplicação "Chatbot"
│
├───Database
│       script_chatbot.sql # Script SQL para o banco do chatbot
│       script_eleve.sql   # Script SQL para o banco do eleve
│
└───Frontend
    └───build         # Build estático do frontend
```

---

## 🛠️ Comandos Úteis

```bash
# Alterar session token da AWS
aws configure set aws_session_token SEU_SESSION_TOKEN

# Editar as variáveis criptografadas
ansible-vault edit secrets.yml

# Redefinir a senha de secrets.yml
ansible-vault rekey secrets.yml

# Criar novo arquivo de variáveis criptografadas
ansible-vault create secrets.yml

# Rodar apenas uma parte do playbook (ex: apenas reconfigurar o Nginx)
ansible-playbook playbook.yml --tags "nginx_config" --ask-vault-pass

# Rodar playbook a partir de uma tarefa específica
ansible-playbook meu_playbook.yml --start-at-task="Nome da tarefa" --ask-vault-pass

# Conectar via SSH em uma máquina privada
ssh -J ubuntu@IP_PUBLICO ubuntu@IP_PRIVADO

# Remover um ip da lista de hosts conhecidos
ssh-keygen -f "/home/SEU_USUARIO/.ssh/known_hosts" -R "IP"

# Ver logs de um container em um dos servidores de backend (via SSH)
# Você precisa estar conectado no servidor de backend primeiro
docker logs -f eleve-app-eleve01

# Destruir toda infraestrutura
terraform destroy
```