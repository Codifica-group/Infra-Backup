# Automação de Infraestrutura AWS com Ansible

Este repositório contém um playbook Ansible projetado para configurar e implantar automaticamente uma aplicação web completa em uma infraestrutura AWS existente. O playbook automatiza a configuração de um bastion host (servidor web), servidores de backend, um banco de dados e o deploy do frontend.

A topologia de rede assume que apenas o servidor web (bastion) é acessível publicamente, e todos os outros servidores (backend, banco de dados) estão em uma sub-rede privada, acessíveis apenas através do bastion usando `ProxyJump`.

## 🏗️ Arquitetura da Aplicação

A infraestrutura configurada por este playbook é composta por:

* **Servidor Web (Nginx):** Atua como proxy reverso para os serviços de backend e serve o frontend estático. Também funciona como **Bastion Host (Jump Host)** para o Ansible.
* **Servidores de Backend:**
    * `Eleve`: Aplicação Java (eleve.jar).
    * `Chatbot`: Aplicação Java (chatbot.jar).
* **Servidor de Banco de Dados:** Servidor MySQL que hospeda os bancos de dados para ambas as aplicações (`script_eleve.sql`, `script_chatbot.sql`).
* **Frontend:** Uma aplicação web estática (build de React/Vue/Angular).

## 📋 Pré-requisitos

Antes de executar o playbook, você precisará de:

1.  **Infraestrutura AWS:** Instâncias EC2 já provisionadas (1 pública para o bastion, e as demais privadas).
2.  **Ansible:** Instalado na sua máquina local ou no WSL.
3.  **Chave SSH (`AWSKey.pem`):** A chave privada SSH (`.pem`) necessária para acessar suas instâncias EC2.
4.  **WSL (Ubuntu):** O guia de execução é baseado em um ambiente WSL (Windows Subsystem for Linux).
5.  **IPs das Instâncias:** Os endereços IP públicos e privados das suas instâncias EC2.

---

## ⚙️ Configuração

Siga estes passos para configurar o ambiente antes de executar o playbook.

### 1. Chave de Acesso AWS

Coloque sua chave privada SSH (`.pem`) na raiz deste repositório e renomeie-a para `AWSKey.pem`.

> **⚠️ ATENÇÃO: Segurança**
> O arquivo `AWSKey.pem` **NUNCA** deve ser comitado no repositório Git. Adicione-o imediatamente ao seu arquivo `.gitignore`:
>
> ```bash
> echo "AWSKey.pem" >> .gitignore
> ```

### 2. Inventário (`inventory.ini`)

Edite o arquivo `inventory.ini` e substitua os placeholders (`IP_PUBLICO_DO_WEB`, `IP_PRIVADO_...`) pelos endereços IP corretos das suas instâncias EC2.

O arquivo deve se parecer com isto:

```ini
[webserver]
web1 ansible_host=SEU_IP_PUBLICO_DO_WEB

[eleve_servers]
eleve1 ansible_host=SEU_IP_PRIVADO_ELEVE_1
eleve2 ansible_host=SEU_IP_PRIVADO_ELEVE_2

[chatbot_servers]
chat1 ansible_host=SEU_IP_PRIVADO_CHATBOT

[db_server]
db1 ansible_host=SEU_IP_PRIVADO_DB

[backend_servers:children]
eleve_servers
chatbot_servers

[privatenet:children]
eleve_servers
chatbot_servers
db_server

[all:vars]
ansible_user=ubuntu

[privatenet:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@SEU_IP_PUBLICO_DO_WEB'
```

### 3. Variáveis Criptografadas (secrets.yml)

Este arquivo armazena dados sensíveis, como senhas de banco de dados. Use o ansible-vault para editá-lo e inserir suas credenciais. Você será solicitado a criar uma senha para o "vault".

```bash
ansible-vault edit secrets.yml
```

### 🚀 Como Executar (Usando WSL)

Estes passos detalham como executar o playbook a partir de um terminal WSL (Ubuntu).

#### 1. Copiar Arquivos para o WSL

Copie o diretório do projeto do Windows para o seu ambiente WSL (substitua pelo seu caminho real).

```bash
# Exemplo de comando para copiar do Windows para o home do WSL
sudo cp -r "/mnt/c/Users/SEU_USUARIO/CAMINHO_DO_REPOSITORIO/Infra-Backup" ~/

# Entrar no diretório do projeto
cd ~/Infra-Backup
```

#### 2. Configurar Permissões da Chave SSH

O SSH e o Ansible são muito rigorosos quanto às permissões da chave.

```bash
# 1. Mudar o dono da chave para o seu usuário (crítico!)
# (O 'root' não pode ser o dono se você estiver executando como 'ubuntu')
sudo chown $USER:$USER SUA_CHAVE_AWS.pem

# 2. Definir permissões restritas (leitura/escrita apenas para o dono)
chmod 600 ./SUA_CHAVE_AWS.pem
```

#### 3. Adicionar Chave ao SSH Agent

Isso permite que o Ansible use a chave para o ProxyJump (conexão bastion) sem pedir a senha da chave.

```bash
# Iniciar o ssh-agent em segundo plano
eval $(ssh-agent -s)

# Adicionar sua chave ao agent
ssh-add ./SUA_CHAVE_AWS.pem
```

#### 4. Testar a Conexão (Opcional, mas recomendado)

Antes de rodar o playbook, verifique se você consegue acessar uma máquina privada (ex: o DB) através do bastion.

```bash
# Use os IPs do seu inventory.ini
ssh -J ubuntu@SEU_IP_PUBLICO_DO_WEB ubuntu@SEU_IP_PRIVADO_DB
```

Se a conexão for bem-sucedida, você pode sair (exit) e prosseguir.

#### 5. Executar o Playbook Ansible

Finalmente, execute o playbook. Você precisará fornecer a senha do "vault" que criou no Passo 3 da Configuração.

```bash
ansible-playbook playbook.yml --ask-vault-pass
```

O Ansible agora se conectará ao bastion (web1) e, a partir dele, pulará para as máquinas privadas para executar todas as tarefas de configuração e deploy.

### 📂 Estrutura do Repositório
```ini
C:.
│   ansible.cfg       # Configurações do Ansible (ex: caminho do inventário)
│   inventory.ini     # Inventário de hosts (servidores)
│   nginx.conf.j2     # Template Jinja2 para a configuração do Nginx
│   playbook.yml      # O playbook principal que orquestra tudo
│   README.md         # Este arquivo
│   secrets.yml       # (CRIPTOGRAFADO) Variáveis sensíveis (senhas, etc.)
│
├───Backend
│       eleve.jar     # Artefato da aplicação "Eleve"
│
├───Chatbot
│       chatbot.jar   # Artefato da aplicação "Chatbot"
│
├───Database
│       script_chatbot.sql # Script SQL para o banco do chatbot
│       script_eleve.sql   # Script SQL para o banco do eleve
│
└───Frontend
    └───build         # Build estático do frontend
```

ansible-playbook playbook.yml --tags "nginx_config" --ask-vault-pass