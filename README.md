# Cebolinha 🧅🛡️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Cebolinha** é um script Bash profissional e "fire-and-forget" que reconfigura de forma permanente um sistema operacional baseado em Debian/Ubuntu para **rotear todo o tráfego de rede através da rede Tor**.

É a solução definitiva para transformar sua máquina em um ambiente com privacidade e anonimato a nível de sistema, ideal para:
- Proteger sua identidade e atividades em redes Wi-Fi públicas
- Contornar censura e acessar conteúdo bloqueado geograficamente
- Garantir que todas as aplicações (e não apenas o navegador) se comuniquem anonimamente
- Pesquisas de segurança e análise de redes

---

## 📦 O que o Cebolinha faz

- 🔍 **Instalação Inteligente:** Verifica e instala todas as dependências necessárias, como `tor` e `iptables-persistent`, de forma não interativa.
- ⚙️ **Configuração Automática do Tor:** Edita o arquivo `torrc` para habilitar o proxy transparente (`TransPort`) e o resolvedor de DNS (`DNSPort`), garantindo que o serviço esteja pronto para a tarefa.
- 🔥 **Orquestração de Firewall (Iptables):** Implementa um conjunto de regras de `iptables` robusto para redirecionar todo o tráfego TCP e consultas DNS para o Tor, efetivamente fechando a porta para conexões diretas.
- 🛡️ **Proteção Anti-Vazamento:** Bloqueia ativamente tráfego que poderia vazar sua identidade (como pacotes UDP e ICMP não relacionados a DNS), garantindo que apenas o tráfego "torificado" saia da sua máquina.
- 💾 **Persistência de Regras:** Salva a configuração do firewall para que ela seja recarregada automaticamente a cada inicialização do sistema, tornando a proteção permanente.
- 📜 **Execução Robusta:** Utiliza `set -e` para parar a execução imediatamente em caso de erro e verifica privilégios de root para evitar falhas de permissão.

---

## 🛡️ Arquitetura de Segurança: Tor + Iptables

O poder do **Cebolinha** reside na combinação de duas tecnologias de nível de sistema:

- **Tor (The Onion Router):** Garante o anonimato através de um processo de roteamento em camadas. Seu tráfego passa por uma série de relés voluntários ao redor do mundo, tornando extremamente difícil rastrear a origem da conexão. O Cebolinha configura o Tor não como um simples proxy SOCKS, mas como um gateway transparente para todo o sistema.

- **Iptables:** É o firewall nativo do kernel Linux. Ao manipular as regras de `iptables` diretamente, o Cebolinha intercepta o tráfego na camada mais baixa possível do sistema operacional. Isso é mais eficaz do que soluções baseadas em proxy de aplicação, pois força **todas as ferramentas e programas** a passarem pelo Tor, quer eles tenham sido projetados para isso ou não.

A união dessas duas tecnologias cria um "portal de saída" único e anônimo para o seu sistema.

---

## ⚠️ AVISO IMPORTANTE

Este script realiza mudanças profundas e **permanentes** na configuração de rede do seu sistema.
- **É uma via de mão única:** O script não possui um comando para "desfazer". A remoção da configuração exige conhecimento manual de `iptables` e `systemd`.
- **Impacto na Velocidade:** Sua conexão com a internet se tornará visivelmente mais lenta, o que é uma característica inerente da rede Tor.
- **Possíveis Bloqueios:** Alguns serviços, sites e plataformas online bloqueiam ativamente o acesso vindo de nós de saída da rede Tor.

**Use este script por sua conta e risco.**

---

## ⚙️ Requisitos

- Um sistema operacional baseado em Debian (ex: **Ubuntu 22.04+, Debian 11+, Linux Mint 21+**)
- Acesso de superusuário (root/sudo)
- Uma conexão ativa com a internet para o download dos pacotes

---

## 🚀 Como Usar

A filosofia do Cebolinha é a de "execução única". Não há nada para configurar no arquivo.

**1. Clone o repositório oficial:**
```bash
git clone [https://github.com/henriquetourinho/cebolinha.git](https://github.com/henriquetourinho/cebolinha.git)
cd cebolinha
```

**2. Dê permissão de execução ao script:**
```bash
chmod +x cebolinha.sh
```

**3. Execute com privilégios de superusuário:**
```bash
sudo ./cebolinha.sh
```
O script cuidará de todo o resto. Ao final, seu sistema estará totalmente configurado.

---

## 🔍 Como verificar se funcionou?

Após a execução bem-sucedida, você pode verificar seu novo endereço de IP público. Ele deve ser diferente do seu IP real. Abra o terminal e execute:

```bash
curl [https://check.torproject.org/api/ip](https://check.torproject.org/api/ip)
```
O resultado deve mostrar um endereço de IP pertencente à rede Tor.

---

## 📜 Licença

Este projeto está licenciado sob a **MIT License**. Veja o arquivo `LICENSE` no repositório para mais detalhes.