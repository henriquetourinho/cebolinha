# Cebolinha 🧅🛡️

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Cebolinha** é um script Bash profissional e "fire-and-forget" que reconfigura de forma permanente um sistema operacional baseado em Debian/Ubuntu para **rotear todo o tráfego de rede através da rede Tor** com killswitch ativo, bloqueio de IPv6 e proteções anti-vazamento.

Anonimato não pode depender apenas do navegador. O Cebolinha força o sistema inteiro a sair pela rede Tor, bloqueia rotas diretas e reduz caminhos capazes de revelar identidade, localização ou IP real.

É a solução definitiva para transformar sua máquina em um ambiente com privacidade e anonimato a nível de sistema, ideal para:
- Jornalistas e ativistas sob regimes repressivos
- Pesquisadores e comunicadores em ambientes hostis
- Pessoas sob censura ou vigilância que precisam operar em redes públicas
- Defensores de direitos humanos que dependem de anonimato para proteger fontes
- Qualquer pessoa que precise garantir que todas as aplicações (não apenas o navegador) se comuniquem anonimamente

---

## 📦 O que o Cebolinha faz

- 🧅 **Tor Transparente Sistêmico:** Força TODO o tráfego TCP do sistema através da rede Tor, não apenas o navegador. Cada aplicação, serviço e processo de rede é roteado anonimamente sem configuração individual.
- 🔒 **DNS Protegido via Tor:** Redireciona todas as consultas DNS para o resolvedor do Tor, eliminando vazamento de domínios consultados para o provedor de internet ou redes locais.
- ⚡ **Killswitch Ativo:** Monitora continuamente a conexão Tor. Se o circuito cair, bloqueia instantaneamente todo o tráfego de saída, impedindo que dados trafeguem pela rede real.
- 🚫 **Bloqueio Total de IPv6:** Desabilita completamente o IPv6 no kernel e firewall. O IPv6 é uma das maiores causas de vazamento de IP real em sistemas que usam Tor.
- 🌉 **Bridges Anti-Censura:** Suporte a bridges obfs4 para contornar bloqueios profundos de rede, como os praticados por regimes autoritários que bloqueiam ativamente a rede Tor.
- 🎭 **MAC Spoofing Opcional:** Randomiza o endereço MAC da interface de rede, dificultando rastreamento físico e correlação de atividades em redes diferentes.
- 🛡️ **Anti-Vazamento Multicamada:** Bloqueia tráfego UDP não-DNS, ICMP, source routing e outros vetores de vazamento de identidade.
- 🔒 **Isolamento de Streams:** Configura o Tor para isolar circuitos por destino e porta, dificultando correlação de tráfego entre diferentes serviços acessados.
- 🧬 **Hardening do Kernel:** Aplica parâmetros de segurança no kernel Linux: anti-spoofing, proteção contra SYN flood, desabilita redirects ICMP e restringe acesso a informações do kernel.
- 📜 **Backup Inteligente:** Salva automaticamente todas as configurações anteriores (iptables, Tor, DNS, sysctl) permitindo restauração manual se necessário.
- 🔍 **Verificação Automática:** Testa a conexão Tor após configuração, verifica se o IP de saída é diferente do IP real e realiza testes de vazamento de DNS e IPv6.

---

## 🎯 Casos de Uso Reais

### 1. Jornalista Investigativo em País com Censura
**Cenário:** Um jornalista no Irã investiga corrupção governamental. O regime bloqueia ativamente o Tor, sites de notícias independentes e ferramentas de comunicação criptografada. Ele precisa acessar fontes internacionais, enviar matérias e se comunicar com editores sem ser rastreado.

**Configuração:**
- Laptop com Ubuntu 22.04 LTS
- Cebolinha instalado com bridges obfs4 ativas
- Killswitch configurado para bloquear internet se Tor cair
- MAC spoofing ativado para redes públicas

**Evento real:**
O jornalista se conecta a uma rede Wi-Fi pública em um café. O Cebolinha força todo o tráfego pelo Tor via bridges, tornando invisível para o firewall nacional o fato de que ele está usando Tor (obfs4 faz o tráfego parecer ruído aleatório). Ele acessa o Signal Desktop, envia sua matéria por e-mail via Thunderbird e faz upload de documentos para um servidor seguro — tudo anonimizado. O killswitch garante que, se a bridge cair, a conexão é cortada antes de qualquer pacote vazar.

**Resultado:** Matéria publicada no exterior. Fontes protegidas. Firewall nacional não detectou uso de Tor.

---

### 2. Ativista de Direitos Humanos em Zona de Conflito
**Cenário:** Uma defensora de direitos humanos na Ucrânia documenta crimes de guerra. Forças hostis monitoram ativamente a rede local e provedores de internet colaboram com autoridades. Ela precisa enviar evidências para tribunais internacionais sem revelar sua localização.

**Configuração:**
- Laptop com Debian 12
- Cebolinha com bridges configuradas manualmente
- Killswitch ativo 24/7
- DNS exclusivamente via Tor

**Evento real:**
A ativista coleta vídeos e fotos de ataques a civis. Conecta o laptop a um ponto de Wi-Fi compartilhado em um abrigo. O Cebolinha força todas as conexões pelo Tor — o cliente Nextcloud para upload de arquivos, o navegador para pesquisar jurisprudência internacional, o cliente de e-mail para contato com advogados. O bloqueio de IPv6 impede que o sistema operacional tente conexões diretas pelo protocolo IPv6 (comum em redes modernas). O DNS via Tor impede que o provedor local veja quais domínios ela está acessando.

**Resultado:** Evidências chegam ao Tribunal Penal Internacional. Provedor local não tem logs de domínios acessados. Localização física permanece desconhecida.

---

### 3. Pesquisador de Segurança em Rede Corporativa Hostil
**Cenário:** Um pesquisador de segurança digital investiga malware patrocinado por Estado. Ele precisa acessar servidores de comando e controle, baixar amostras e analisar infraestrutura de ataque sem revelar o IP de seu laboratório (que poderia ser retaliado).

**Configuração:**
- Servidor dedicado com Ubuntu Server 22.04 LTS
- Cebolinha instalado com saída por nós na Suíça e Holanda
- Killswitch configurado para segurança máxima
- MAC spoofing desativado (servidor fixo)

**Evento real:**
O pesquisador usa ferramentas como `wget`, `curl`, `nmap` e scripts Python personalizados para interagir com infraestrutura maliciosa. Todas essas ferramentas — mesmo as que não têm suporte nativo a SOCKS — são forçadas pelo Tor via transparente proxy. O isolamento de streams garante que cada servidor malicioso receba conexões de circuitos Tor diferentes, impedindo que operadores do malware correlacionem as atividades e descubram que se trata do mesmo pesquisador.

**Resultado:** Análise completa sem revelar IP do laboratório. Operadores do malware não conseguem rastrear a origem da investigação.

---

### 4. Fonte Anônima em Processo de Vazamento
**Cenário:** Um servidor público decide vazar documentos que comprovam esquema de corrupção. Ele precisa se comunicar com jornalistas, pesquisar advogados especializados em whistleblowing e acessar a plataforma SecureDrop — tudo sem deixar rastros em seu provedor de internet ou no firewall corporativo.

**Configuração:**
- Pendrive bootável com Ubuntu 22.04
- Cebolinha instalado com bridges (rede corporativa bloqueia Tor)
- Killswitch ativo para segurança máxima
- Todo o sistema operacional temporário

**Evento real:**
O servidor boota o Ubuntu pelo pendrive em um laptop pessoal, conecta-se a uma rede Wi-Fi pública longe de casa e do trabalho. O Cebolinha força todo o tráfego pelo Tor com bridges obfs4. Ele acessa o SecureDrop do jornal, envia documentos via navegador Tor Browser (que já está configurado) E também usa o cliente de e-mail Thunderbird configurado para ProtonMail — tudo anonimizado pelo transparente proxy. O DNS via Tor impede que o provedor de internet saiba quais serviços ele acessou. Ao remover o pendrive e desligar o laptop, zero vestígios no disco.

**Resultado:** Documentos publicados. Fonte permanece anônima. Provedor de internet não tem registros utilizáveis.

---

### 5. Equipe de Documentação em Território Indígena
**Cenário:** Uma equipe de documentaristas e antropólogos trabalha em território indígena na Amazônia registrando invasões de garimpeiros. A região tem conexão via satélite monitorada. Eles precisam enviar relatórios, coordenadas GPS e vídeos para organizações internacionais sem revelar sua posição exata.

**Configuração:**
- Múltiplos laptops com Linux Mint
- Cebolinha instalado em cada máquina
- Bridges configuradas (conexão via satélite tem latência alta)
- Killswitch essencial (conexão instável)

**Evento real:**
A equipe se conecta via terminal Starlink (ou satélite geoestacionário). O Cebolinha força todo o tráfego pelo Tor. Quando a conexão via satélite oscila e o circuito Tor cai, o killswitch bloqueia imediatamente todo o tráfego — impedindo que dados trafeguem pela rede real antes do Tor restabelecer. Eles usam o cliente de e-mail Evolution para enviar relatórios criptografados, o navegador para acessar mapas de desmatamento e o QGIS para baixar imagens de satélite — tudo anonimizado.

**Resultado:** Relatórios chegam a ONGs internacionais. Localização da equipe permanece protegida mesmo com conexão instável.

---

## 🔧 Funcionamento Técnico Detalhado

O Cebolinha opera em **7 camadas de proteção** que transformam o sistema em uma fortaleza de anonimato:

### Camada 1: Transparente Proxy TCP via Tor

**O coração do anonimato.**

Diferente de configurar um proxy SOCKS aplicação por aplicação, o Cebolinha usa o `TransPort` do Tor combinado com `iptables` para interceptar **todo** o tráfego TCP na camada de rede:

```bash
# No torrc
TransPort 9040
TransListenAddress 0.0.0.0

# No iptables
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports 9040
```

Isso significa que qualquer programa — navegador, cliente de e-mail, Git, SSH, Python, Node.js — tem seu tráfego automaticamente roteado pelo Tor, mesmo que o programa não tenha suporte nativo a proxies.

**O que acontece na prática:**
1. Aplicação tenta conectar a `example.com:443`
2. Kernel Linux gera pacote TCP SYN
3. Regra `iptables` intercepta o pacote na tabela NAT
4. Pacote é redirecionado para `127.0.0.1:9040` (TransPort do Tor)
5. Tor recebe o fluxo TCP, resolve o destino, cria circuito e encaminha

### Camada 2: DNS Seguro via Tor

**Vazamento de DNS é o erro mais comum.**

Sem proteção, o sistema consulta servidores DNS do provedor (8.8.8.8, 1.1.1.1) revelando todos os domínios acessados. O Cebolinha resolve isso em duas frentes:

```bash
# No torrc
DNSPort 5353
DNSListenAddress 0.0.0.0

# No iptables
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports 5353
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports 5353
```

Todas as consultas DNS (UDP e TCP) são sequestradas e respondidas pelo Tor, que resolve o domínio através do circuito anônimo. O arquivo `/etc/resolv.conf` é sobrescrito para apontar para `127.0.0.1` e tornado imutável com `chattr +i`.

### Camada 3: Killswitch Ativo

**Se Tor cair, internet morre.**

O killswitch é um serviço systemd que monitora continuamente a conexão Tor:

```bash
while true; do
    if ! check_tor; then
        ((FAIL_COUNT++))
        if [[ $FAIL_COUNT -ge 3 ]]; then
            # Bloqueia TODO tráfego de saída
            iptables -F OUTPUT
            iptables -P OUTPUT DROP
            iptables -A OUTPUT -o lo -j ACCEPT
            wall "⚠️ Tor desconectado! Internet bloqueada."
        fi
    fi
    sleep 5
done
```

**Por que é crítico:** Sem killswitch, se o Tor cair silenciosamente, as aplicações podem tentar conexões diretas pela rede real. O killswitch previne isso em no máximo 15 segundos (3 falhas × 5 segundos).

### Camada 4: Bloqueio Total de IPv6

**IPv6 é o maior vetor de vazamento em 2024.**

Muitos sistemas têm IPv6 habilitado por padrão. Se o Tor não estiver configurado para IPv6 (e frequentemente não está), o sistema pode fazer conexões diretas via IPv6, ignorando completamente as regras de IPv4:

```bash
# Desabilita no kernel
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Bloqueia no firewall
ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP
```

**Resultado:** Zero tráfego IPv6 possível. Nenhum vazamento por esse vetor.

### Camada 5: Bridges obfs4 Anti-Censura

**Para países que bloqueiam o Tor.**

Regimes como China, Irã, Rússia e Turquia usam DPI (Deep Packet Inspection) para detectar e bloquear tráfego Tor. O Cebolinha integra suporte a bridges obfs4:

```
Bridge obfs4 192.95.36.142:443 CERT... iat-mode=1
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy
```

O tráfego Tor é ofuscado para parecer ruído aleatório, contornando sistemas de DPI. O arquivo `/etc/tor/bridges.conf` é configurado automaticamente.

### Camada 6: Isolamento de Streams (Anti-Correlação)

**Impede que adversários correlacionem suas atividades.**

Por padrão, o Tor pode reutilizar o mesmo circuito para múltiplas conexões. Isso permite que um observador global correlacione tráfego de diferentes serviços:

```bash
IsolateSOCKSAuth
IsolateClientProtocol
IsolateDestPort
IsolateDestAddr
```

Cada destino recebe um circuito diferente. Se você acessa `sitea.com` e `siteb.com`, eles não compartilham o mesmo circuito de saída.

### Camada 7: Hardening do Kernel

**Proteções adicionais contra fingerprinting e ataques:**

```bash
# Anti-spoofing
net.ipv4.conf.all.rp_filter = 1

# Anti-SYN flood
net.ipv4.tcp_syncookies = 1

# Desabilita ICMP redirects
net.ipv4.conf.all.accept_redirects = 0

# Proteção de informações do kernel
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
```

---

## 🛡️ Arquitetura de Segurança: Camadas de Anonimato

```
        ┌─────────────────────────┐
        │   Isolamento de Streams │ ← Anti-correlação
        │   (circuitos separados) │
       ─┼─────────────────────────┼─
      │   Killswitch Ativo        │ ← Bloqueia se Tor cair
     ──┼─────────────────────────┼──
    │   Bloqueio IPv6 Total       │ ← Sem vazamento IPv6
   ───┼─────────────────────────┼───
  │   DNS Seguro via Tor          │ ← Consultas anônimas
 ────┼─────────────────────────┼────
│   Transparente Proxy TCP        │ ← Todo tráfego no Tor
 ────┼─────────────────────────┼────
│   Bridges obfs4                 │ ← Contorna censura DPI
 ─────────────────────────────────────
```

**Princípio fundamental:** Anonimato não pode depender da configuração individual de cada aplicação. O Cebolinha força o anonimato na camada do kernel, onde nenhuma aplicação pode escapar.

---

## ⚠️ AVISO IMPORTANTE

Este script realiza mudanças profundas e **permanentes** na configuração de rede do seu sistema.

- ⚠️ **É uma via de mão única:** O script não possui um comando para "desfazer". A remoção da configuração exige conhecimento manual de `iptables` e `systemd` (backups são salvos em `/etc/cebolinha/backup`).
- 🐢 **Impacto na Velocidade:** Sua conexão com a internet se tornará visivelmente mais lenta (50-70% de perda), característica inerente da rede Tor.
- 🚫 **Possíveis Bloqueios:** Alguns serviços (bancos, Netflix, Google) bloqueiam ou dificultam acesso via Tor.
- 🧅 **Não é anonimato absoluto:** Tor protege o tráfego de rede, mas não impede fingerprinting de navegador, malware ou erros humanos.
- 🔐 **Combine com outras ferramentas:** Use navegador com WebRTC desabilitado, HTTPS Everywhere e, idealmente, o Tor Browser para navegação web.
- 💀 **Para operações de alto risco:** Considere Tails OS em vez de um sistema instalado. O Cebolinha é para uso diário com anonimato razoável, não para ameaças de Estado.

**Use este script por sua conta e risco.**

---

## ⚙️ Requisitos

- Sistema operacional baseado em Debian (Ubuntu 22.04+, Debian 11+, Linux Mint 21+)
- Acesso de superusuário (root/sudo)
- Conexão ativa com a internet para download de pacotes
- Mínimo 512MB RAM e 1GB de espaço em disco

---

## 🚀 Como Usar

A filosofia do Cebolinha é "execute e esqueça". Uma única execução configura tudo permanentemente.

**1. Clone o repositório oficial:**
```bash
git clone https://github.com/henriquetourinho/cebolinha.git
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

O script cuidará de todo o resto. Ele:
- Instala dependências automaticamente
- Faz backup das configurações atuais
- Configura Tor com bridges e killswitch
- Aplica regras de firewall
- Verifica se a conexão Tor está funcionando
- Testa vazamentos de DNS e IPv6

Ao final, seu sistema estará totalmente configurado com todas as proteções ativas.

---

## 🔍 Como Verificar se Funcionou

**Teste 1 - IP de saída Tor:**
```bash
curl https://check.torproject.org/api/ip
```
O resultado deve mostrar `"IsTor":true` e um IP diferente do seu IP real.

**Teste 2 - IP real (para comparação):**
```bash
curl --socks5 127.0.0.1:9050 https://api.ipify.org
```

**Teste 3 - Status do Tor:**
```bash
sudo systemctl status tor
```

**Teste 4 - Monitoramento em tempo real:**
```bash
sudo nyx
```

**Teste 5 - Killswitch:**
```bash
# Pare o Tor e tente acessar qualquer site
sudo systemctl stop tor
ping google.com  # Deve falhar completamente
sudo systemctl start tor  # Restaura conexão
```

---

## 📍 Configuração Pós-Instalação

### Bridges (obrigatório em países com censura)

1. Obtenha bridges reais em: https://bridges.torproject.org/bridges?transport=obfs4
2. Edite o arquivo de bridges:
```bash
sudo nano /etc/tor/bridges.conf
```
3. Substitua pelas bridges reais
4. Ative o uso de bridges:
```bash
sudo nano /etc/tor/torrc
# Mude: UseBridges 0  →  UseBridges 1
```
5. Reinicie o Tor:
```bash
sudo systemctl restart tor
```

### WebRTC (crítico para navegadores)

Desabilite WebRTC no seu navegador. O WebRTC pode vazar seu IP real mesmo com todo o tráfego passando pelo Tor.

### Aplicações Específicas

A maioria das aplicações funcionará automaticamente. Para aplicações que fazem conexões UDP intensivas (VoIP, videoconferência), o Tor não é adequado devido ao bloqueio de UDP (necessário para segurança).

---

## 📜 Licença

Este projeto está licenciado sob a **MIT License**. Veja o arquivo `LICENSE` no repositório para mais detalhes.

---

## 🌐 Redes e Contato

- **Autor:** Carlos Henrique Tourinho Santana
- **Website:** [henriquetourinho.com.br](https://henriquetourinho.com.br)
- **Instagram:** [@henrique_ntxa](https://instagram.com/henrique_ntxa)
- **Threads:** [@henrique_ntxa](https://threads.net/@henrique_ntxa)
- **GitHub:** [github.com/henriquetourinho](https://github.com/henriquetourinho)
- **Debian Wiki:** [wiki.debian.org/henriquetourinho](https://wiki.debian.org/henriquetourinho)

---

**Projetos irmãos:**
- [Destruidor](https://github.com/henriquetourinho/destruidor) - Destruição emergencial de dados
- [Sentinela](https://github.com/henriquetourinho/sentinela) - Sistema de alerta antecipado com ESP32
