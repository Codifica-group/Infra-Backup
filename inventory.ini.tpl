[webserver]
web1 ansible_host=${web_public_ip}

[eleve_servers]
eleve1 ansible_host=${eleve1_private_ip}
eleve2 ansible_host=${eleve2_private_ip}

[chatbot_servers]
chat1 ansible_host=${chat1_private_ip}

[db_server]
db1 ansible_host=${db1_private_ip}

[backend_servers:children]
eleve_servers
chatbot_servers

[privatenet:children]
eleve_servers
chatbot_servers
db_server

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/AWSKey.pem

[privatenet:vars]
ansible_ssh_common_args='-o ProxyJump=ubuntu@${web_public_ip}'