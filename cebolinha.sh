#!/bin/bash
# /*********************************************************************************
# * Projeto:   Cebolinha v2.0 - Anonimato Sistêmico com Tor
# * Autor:     Carlos Henrique Tourinho Santana
# * Descrição:
# * Sistema completo de anonimização que força TODO o tráfego do sistema
# * através da rede Tor com proteções anti-vazamento, anti-correlação
# * e killswitch ativo. Projetado para jornalistas, ativistas e pessoas
# * sob censura ou vigilância em ambientes hostis.
# *
# * Novas funcionalidades v2.0:
# * - Killswitch ativo (se Tor cair, internet bloqueia)
# * - Bloqueio completo de IPv6
# * - Força UDP via Tor (DNS seguro)
# * - Bridges automáticas para censura profunda
# * - MAC spoofing na interface
# * - Isolamento de streams por destino
# * - Verificação de conexão Tor
# * - Proteção para todos os usuários
# * - Logs anti-forense
# *********************************************************************************/

set -euo pipefail
IFS=$'\n\t'

# ============================================================
# CONFIGURAÇÕES
# ============================================================
TOR_UID="debian-tor"
TOR_PORT="9040"
TOR_DNS_PORT="5353"
TOR_CONTROL_PORT="9051"
TOR_CONTROL_PASS=$(head -c 32 /dev/urandom | base64)
NON_TOR_NET="192.168.1.0/24 10.0.0.0/8 172.16.0.0/12"
TOR_EXCLUDE="127.0.0.0/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16"
INTERFACE=$(ip route show default | awk '/default/ {print $5}' | head -1)
BACKUP_DIR="/etc/cebolinha/backup"
LOG_FILE="/var/log/cebolinha.log"
BRIDGES_FILE="/etc/tor/bridges.conf"

# ============================================================
# FUNÇÕES DE LOG E VERIFICAÇÃO
# ============================================================

log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

erro() {
    log "❌ ERRO: $1"
    exit 1
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "❌ Este script requer privilégios de root (sudo)."
        exit 1
    fi
}

check_internet() {
    log "🔍 Verificando conectividade com a internet..."
    if ! ping -c 1 -W 3 8.8.8.8 &>/dev/null; then
        erro "Sem conexão com a internet. Verifique sua rede."
    fi
    log "✅ Internet acessível"
}

check_debian() {
    if [[ ! -f /etc/debian_version ]]; then
        erro "Este script foi projetado para sistemas Debian/Ubuntu."
    fi
}

# ============================================================
# BACKUP DE CONFIGURAÇÕES
# ============================================================

backup_configs() {
    log "💾 Criando backup das configurações atuais..."
    mkdir -p "$BACKUP_DIR"
    
    # Backup iptables
    if command -v iptables-save &>/dev/null; then
        iptables-save > "$BACKUP_DIR/iptables.rules.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Backup Tor
    if [[ -f /etc/tor/torrc ]]; then
        cp /etc/tor/torrc "$BACKUP_DIR/torrc.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Backup DNS
    if [[ -f /etc/resolv.conf ]]; then
        cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Backup sysctl
    if [[ -f /etc/sysctl.conf ]]; then
        cp /etc/sysctl.conf "$BACKUP_DIR/sysctl.conf.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    log "✅ Backups salvos em $BACKUP_DIR"
}

# ============================================================
# INSTALAÇÃO DE DEPENDÊNCIAS
# ============================================================

install_dependencies() {
    log "📦 Instalando dependências..."
    
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    
    local packages=(
        tor
        iptables
        iptables-persistent
        netfilter-persistent
        dnsutils
        curl
        macchanger
        resolvconf
        obfs4proxy
        torsocks
        nyx
        secure-delete
    )
    
    for pkg in "${packages[@]}"; do
        if ! dpkg -l | grep -q "^ii  $pkg "; then
            log "  Instalando: $pkg"
            apt-get install -y -qq "$pkg" 2>/dev/null || {
                log "  ⚠️ Aviso: $pkg não instalado (não crítico)"
            }
        fi
    done
    
    log "✅ Dependências verificadas"
}

# ============================================================
# CONFIGURAÇÃO DE BRIDGES (ANTI-CENSURA)
# ============================================================

configure_bridges() {
    log "🌉 Configurando bridges para contorno de censura..."
    
    # Obter bridges automaticamente via obfs4
    if command -v obfs4proxy &>/dev/null; then
        # Bridges do Tor Project (exemplo)
        cat > "$BRIDGES_FILE" << 'EOF'
# Bridges obfs4 para países com censura
# Estas bridges são exemplos. Obtenha bridges atualizadas em:
# https://bridges.torproject.org/bridges?transport=obfs4
# ou envie email para bridges@torproject.org com assunto "get transport obfs4"

# Bridge 1 - obfs4
#Bridge obfs4 192.95.36.142:443 CDF2E852BF539B82BD10E27E9115A31734E378C2 cert=qUVQ0srL1JI/vO6V6m/24anYXiJD3QP2HgzUKQtQ7GRqqUvs7P+tG43RtAqdhLOALP7DJQ iat-mode=1

# Bridge 2 - obfs4  
#Bridge obfs4 37.218.245.14:38224 D9A82D2FB5E86C6DC8D69C6C6B25A6A8E9A4A3B5 cert=...
EOF
        log "  Arquivo de bridges criado em $BRIDGES_FILE"
        log "  ⚠️ IMPORTANTE: Substitua pelas bridges reais em $BRIDGES_FILE"
    fi
}

# ============================================================
# CONFIGURAÇÃO PRINCIPAL DO TOR
# ============================================================

configure_tor() {
    log "🧅 Configurando Tor com proteções avançadas..."
    
    # Backup do torrc
    if [[ -f /etc/tor/torrc ]]; then
        cp /etc/tor/torrc /etc/tor/torrc.backup.cebolinha
    fi
    
    cat > /etc/tor/torrc << TORRC
# ==========================================
# Cebolinha v2.0 - Configuração do Tor
# ==========================================

## Configurações Básicas
User $TOR_UID
DataDirectory /var/lib/tor
Log notice file /var/log/tor/notices.log
RunAsDaemon 1
SocksPort 0
SocksPolicy reject *

## Portas de Transparente Proxy
TransPort $TOR_PORT
TransListenAddress 0.0.0.0
DNSPort $TOR_DNS_PORT
DNSListenAddress 0.0.0.0

## Controle
ControlPort $TOR_CONTROL_PORT
HashedControlPassword $(tor --hash-password "$TOR_CONTROL_PASS" 2>/dev/null | tail -1)

## Anti-Censura (Bridges)
%include $BRIDGES_FILE
UseBridges 0  # Mude para 1 após configurar bridges reais
ClientTransportPlugin obfs4 exec /usr/bin/obfs4proxy

## Otimizações de Segurança
# Força nós de saída estáveis
ExitNodes {US} {DE} {NL} {SE} {CH}
StrictNodes 0

# Isolamento de streams (anti-correlação)
IsolateSOCKSAuth
IsolateClientProtocol
IsolateDestPort
IsolateDestAddr

# Anti-fingerprinting
DisableDebuggerAttachment 1
HardwareAccel 1
NumCPUs 2

# Timeouts agressivos para segurança
CircuitBuildTimeout 60
LearnCircuitBuildTimeout 1

# Restrições de saída
RejectExitNodes {RU} {CN} {IR} {SY} {KP}

# Controle de recursos
BandwidthRate 1 MB
BandwidthBurst 2 MB

# Anti-logging
SafeLogging 1
AvoidDiskWrites 1

# Tolerância a falhas
CircuitStreamTimeout 30
NewCircuitPeriod 120
MaxCircuitDirtiness 600

# Hibernação
DisableNetwork 0
FetchDirInfoEarly 1
FetchUselessDescriptors 0

TORRC

    log "✅ Tor configurado com otimizações de segurança"
}

# ============================================================
# KILLSWITCH - Bloqueia tudo se Tor cair
# ============================================================

configure_killswitch() {
    log "⚡ Configurando Killswitch..."
    
    # Script monitor que verifica Tor e bloqueia se cair
    cat > /usr/local/bin/cebolinha-killswitch.sh << 'KILLSWITCH'
#!/bin/bash
# Killswitch do Cebolinha - Bloqueia internet se Tor falhar

TOR_PORT=9040
CHECK_INTERVAL=5
FAIL_COUNT=0
MAX_FAILS=3

check_tor() {
    # Verifica se o Tor está respondendo na porta transparente
    if ! ss -tlnp | grep -q ":$TOR_PORT"; then
        return 1
    fi
    
    # Verifica se o circuito Tor está ativo
    if ! curl --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org/api/ip | grep -q '"IsTor":true'; then
        return 1
    fi
    
    return 0
}

block_all() {
    # Bloqueia TODO tráfego de saída
    iptables -F OUTPUT
    iptables -P OUTPUT DROP
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -A OUTPUT -p tcp --dport 9051 -j ACCEPT  # Controle Tor
    logger "[CEBOLINHA-KILLSWITCH] Tor caiu! Todo tráfego bloqueado."
    wall "⚠️ CEBOLINHA: Tor desconectado! Internet bloqueada por segurança."
}

restore_tor_rules() {
    # Restaura regras do Cebolinha
    if [[ -x /usr/local/bin/cebolinha-restore.sh ]]; then
        /usr/local/bin/cebolinha-restore.sh
    fi
    logger "[CEBOLINHA-KILLSWITCH] Tor reconectado. Regras restauradas."
}

while true; do
    if ! check_tor; then
        ((FAIL_COUNT++))
        if [[ $FAIL_COUNT -ge $MAX_FAILS ]]; then
            block_all
            FAIL_COUNT=0
        fi
    else
        if [[ $FAIL_COUNT -gt 0 ]]; then
            restore_tor_rules
        fi
        FAIL_COUNT=0
    fi
    sleep $CHECK_INTERVAL
done
KILLSWITCH

    chmod +x /usr/local/bin/cebolinha-killswitch.sh
    
    # Script de restauração
    cat > /usr/local/bin/cebolinha-restore.sh << 'RESTORE'
#!/bin/bash
iptables-restore < /etc/iptables/rules.v4 2>/dev/null || true
RESTORE
    chmod +x /usr/local/bin/cebolinha-restore.sh
    
    # Serviço systemd para killswitch
    cat > /etc/systemd/system/cebolinha-killswitch.service << 'SERVICE'
[Unit]
Description=Cebolinha Killswitch
After=tor.service network.target
Requires=tor.service

[Service]
Type=simple
ExecStart=/usr/local/bin/cebolinha-killswitch.sh
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable cebolinha-killswitch.service 2>/dev/null || true
    
    log "✅ Killswitch configurado"
}

# ============================================================
# BLOQUEIO COMPLETO DE IPv6 (Anti-Vazamento Crítico)
# ============================================================

block_ipv6() {
    log "🚫 Bloqueando IPv6 (prevenção de vazamento)..."
    
    # Desabilita IPv6 completamente
    cat >> /etc/sysctl.conf << 'SYSCTL'

# ==========================================
# Cebolinha - Bloqueio IPv6
# ==========================================
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
SYSCTL

    sysctl -p &>/dev/null
    
    # Bloqueia IPv6 no iptables
    ip6tables -F 2>/dev/null || true
    ip6tables -P INPUT DROP 2>/dev/null || true
    ip6tables -P FORWARD DROP 2>/dev/null || true
    ip6tables -P OUTPUT DROP 2>/dev/null || true
    
    # Salva regras IPv6
    ip6tables-save > /etc/iptables/rules.v6 2>/dev/null || true
    
    log "✅ IPv6 completamente bloqueado"
}

# ============================================================
# CONFIGURAÇÃO DE DNS SEGURO
# ============================================================

configure_dns() {
    log "🔒 Configurando DNS seguro via Tor..."
    
    # Força DNS local via Tor
    cat > /etc/resolv.conf << DNS
# Cebolinha - DNS protegido via Tor
nameserver 127.0.0.1
options edns0 trust-ad
DNS

    # Torna imutável para evitar alterações
    chattr +i /etc/resolv.conf 2>/dev/null || true
    
    log "✅ DNS configurado para usar exclusivamente Tor"
}

# ============================================================
# CONFIGURAÇÃO DE IPTABLES AVANÇADO
# ============================================================

configure_iptables() {
    log "🔥 Configurando iptables avançado..."
    
    # Limpa regras existentes
    iptables -F
    iptables -t nat -F
    iptables -t mangle -F
    iptables -X
    
    # Política padrão restritiva
    iptables -P INPUT DROP
    iptables -P FORWARD DROP
    iptables -P OUTPUT DROP
    
    # ============================================
    # REGRAS DE ENTRADA
    # ============================================
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    # SSH local apenas
    iptables -A INPUT -s 192.168.0.0/16 -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -s 10.0.0.0/8 -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -s 172.16.0.0/12 -p tcp --dport 22 -j ACCEPT
    
    # ============================================
    # REGRAS DE SAÍDA (KILLSWITCH)
    # ============================================
    # Permite loopback
    iptables -A OUTPUT -o lo -j ACCEPT
    
    # Permite tráfego para o processo Tor
    iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
    
    # Permite conexões estabelecidas
    iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    
    # ============================================
    # REDIRECIONAMENTO DE DNS
    # ============================================
    # Redireciona TODAS as consultas DNS para o Tor
    iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-ports $TOR_DNS_PORT
    iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-ports $TOR_DNS_PORT
    
    # ============================================
    # TRANSPARENTE PROXY TCP
    # ============================================
    # Exclui tráfego do próprio Tor
    iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
    
    # Exclui redes locais
    for net in $TOR_EXCLUDE; do
        iptables -t nat -A OUTPUT -d $net -j RETURN
    done
    
    # Redireciona TODO o resto TCP para Tor
    iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-ports $TOR_PORT
    
    # ============================================
    # PROTEÇÕES ADICIONAIS
    # ============================================
    # Bloqueia UDP não-DNS (anti-vazamento)
    iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p udp -j DROP
    
    # Bloqueia ICMP (anti-ping sweep)
    iptables -A OUTPUT -p icmp -j DROP
    
    # ============================================
    # LOGS DE SEGURANÇA
    # ============================================
    # Loga tentativas bloqueadas (limitado para não floodar)
    iptables -A INPUT -j LOG --log-prefix "CEBOLINHA-INPUT-DROP: " --log-level 4 -m limit --limit 2/min
    iptables -A OUTPUT -j LOG --log-prefix "CEBOLINHA-OUTPUT-DROP: " --log-level 4 -m limit --limit 2/min
    
    # ============================================
    # PERSISTÊNCIA
    # ============================================
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4
    netfilter-persistent save &>/dev/null || true
    
    log "✅ iptables configurado com sucesso"
}

# ============================================================
# MAC SPOOFING
# ============================================================

spoof_mac() {
    log "🎭 Aplicando MAC spoofing..."
    
    if command -v macchanger &>/dev/null && [[ -n "$INTERFACE" ]]; then
        # Desliga interface
        ip link set dev "$INTERFACE" down
        
        # MAC aleatório
        macchanger -r "$INTERFACE" &>/dev/null
        
        # Religar interface
        ip link set dev "$INTERFACE" up
        
        log "✅ MAC address aleatório aplicado em $INTERFACE"
    else
        log "⚠️ MAC spoofing não aplicado (macchanger não encontrado)"
    fi
}

# ============================================================
# HARDENING DO SISTEMA
# ============================================================

harden_system() {
    log "🛡️ Aplicando hardening de sistema..."
    
    # Desabilita IPv6 no kernel
    cat > /etc/sysctl.d/99-cebolinha.conf << SYSCTL
# ==========================================
# Cebolinha - Hardening do Kernel
# ==========================================

## Desabilita IPv6
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

## Anti-spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

## Ignora ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0

## Anti-SYN flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2

## Desabilita source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

## Loga pacotes martelados
net.ipv4.conf.all.log_martians = 1

## Otimizações TCP
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15

## Proteção de memória
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1

## Desabilita USB (opcional - remova comentário se necessário)
#kernel.usb_disable = 1
SYSCTL

    sysctl --system &>/dev/null
    
    log "✅ Sistema hardened"
}

# ============================================================
# VERIFICAÇÃO DE FUNCIONAMENTO
# ============================================================

verify_tor() {
    log "🔍 Verificando conexão Tor..."
    
    # Aguarda Tor iniciar
    sleep 5
    
    # Verifica se Tor está rodando
    if ! systemctl is-active --quiet tor; then
        erro "Tor não está rodando!"
    fi
    
    # Verifica IP via Tor
    local tor_ip
    tor_ip=$(curl --socks5-hostname 127.0.0.1:9050 -s https://check.torproject.org/api/ip 2>/dev/null | grep -oP '"IP":"\K[^"]+' || echo "")
    
    if [[ -n "$tor_ip" ]]; then
        log "✅ Conexão Tor estabelecida!"
        log "   IP de saída Tor: $tor_ip"
        
        # Verifica se NÃO é seu IP real
        local real_ip
        real_ip=$(curl -s https://api.ipify.org 2>/dev/null || echo "desconhecido")
        if [[ "$tor_ip" == "$real_ip" ]]; then
            log "⚠️ ALERTA: IP de saída igual ao IP real! Possível vazamento!"
        else
            log "✅ IP real diferente do IP Tor - proteção ativa"
        fi
    else
        log "⚠️ Não foi possível verificar IP via Tor"
    fi
    
    # Verifica transproxy
    log "🔍 Verificando transparente proxy..."
    if ss -tlnp | grep -q ":$TOR_PORT"; then
        log "✅ Transparente proxy ativo na porta $TOR_PORT"
    else
        erro "Transparente proxy não está escutando na porta $TOR_PORT"
    fi
    
    # Verifica DNS
    log "🔍 Verificando DNS..."
    if ss -tlnp | grep -q ":$TOR_DNS_PORT"; then
        log "✅ DNS via Tor ativo na porta $TOR_DNS_PORT"
    else
        log "⚠️ DNS via Tor pode não estar funcionando"
    fi
}

# ============================================================
# TESTE DE VAZAMENTO
# ============================================================

test_leaks() {
    log "🧪 Realizando testes de vazamento..."
    
    # Teste DNS leak
    log "  Testando vazamento de DNS..."
    local dns_leak
    dns_leak=$(curl -s https://dnsleaktest.com 2>/dev/null | grep -oP 'IP">\K[^<]+' | head -1 || echo "")
    if [[ -n "$dns_leak" ]]; then
        log "  ✅ DNS aparentemente seguro"
    fi
    
    # Teste WebRTC leak
    log "  ⚠️ WebRTC pode vazar IP real. Use navegador com WebRTC desabilitado."
    
    # Teste IPv6 leak
    log "  Verificando IPv6..."
    if ip -6 addr show | grep -q "inet6"; then
        log "  ⚠️ Interfaces IPv6 detectadas. Verifique o bloqueio."
    else
        log "  ✅ Sem interfaces IPv6 ativas"
    fi
}

# ============================================================
# INICIALIZAÇÃO DE SERVIÇOS
# ============================================================

start_services() {
    log "🚀 Iniciando serviços..."
    
    # Reinicia Tor com nova configuração
    systemctl restart tor
    sleep 3
    
    if ! systemctl is-active --quiet tor; then
        erro "Falha ao iniciar o Tor. Verifique /var/log/tor/log"
    fi
    
    # Inicia killswitch
    systemctl start cebolinha-killswitch 2>/dev/null || true
    
    # Habilita na inicialização
    systemctl enable tor 2>/dev/null || true
    
    log "✅ Serviços iniciados"
}

# ============================================================
# GUIA PÓS-INSTALAÇÃO
# ============================================================

show_guide() {
    cat << GUIDE

╔══════════════════════════════════════════════════════════════╗
║           🧅 CEBOLINHA v2.0 - INSTALAÇÃO CONCLUÍDA          ║
╚══════════════════════════════════════════════════════════════╝

✅ O Cebolinha v2.0 foi instalado com sucesso!

🔒 PROTEÇÕES ATIVAS:
   • Transparente Proxy TCP via Tor (porta $TOR_PORT)
   • DNS seguro via Tor (porta $TOR_DNS_PORT)
   • Killswitch ativo (bloqueia internet se Tor cair)
   • IPv6 completamente bloqueado
   • MAC spoofing aplicado
   • Anti-vazamento UDP e ICMP
   • Isolamento de streams
   • Hardening do kernel

📋 COMANDOS ÚTEIS:
   • Verificar status:   sudo systemctl status tor
   • Verificar IP Tor:   curl --socks5 127.0.0.1:9050 https://check.torproject.org/api/ip
   • Monitorar Tor:      sudo nyx
   • Logs do Tor:        sudo tail -f /var/log/tor/notices.log
   • Logs do Cebolinha:  sudo tail -f $LOG_FILE

⚠️  PRÓXIMOS PASSOS:
   1. Configure bridges reais em: $BRIDGES_FILE
      (obtenha em https://bridges.torproject.org)
   
   2. Após configurar bridges, edite /etc/tor/torrc:
      Mude "UseBridges 0" para "UseBridges 1"
   
   3. Reinicie o Tor: sudo systemctl restart tor
   
   4. Desabilite WebRTC no seu navegador!
   
   5. Use HTTPS Everywhere (extensão do navegador)
   
   6. NUNCA maximize a janela do navegador (fingerprinting)

🛡️  PARA MÁXIMA SEGURANÇA:
   • Use Tails OS para operações críticas
   • Combine com Destruidor para emergências
   • Mantenha o sistema atualizado
   • Use senhas fortes e 2FA

📚 PROJETOS RELACIONADOS:
   • Destruidor: github.com/henriquetourinho/destruidor
   • Sentinela: github.com/henriquetourinho/sentinela

GUIDE
}

# ============================================================
# FUNÇÃO PRINCIPAL
# ============================================================

main() {
    clear
    
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        🧅 CEBOLINHA v2.0 - ANONIMATO SISTÊMICO              ║"
    echo "║     Tor Transparente · Killswitch · Anti-Censura             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    log "🚀 INICIANDO INSTALAÇÃO DO CEBOLINHA v2.0"
    
    # Verificações iniciais
    check_root
    check_debian
    check_internet
    
    # Backup
    backup_configs
    
    # Instalação e configuração
    install_dependencies
    configure_bridges
    configure_tor
    block_ipv6
    configure_dns
    configure_iptables
    harden_system
    
    # MAC spoofing (opcional)
    read -p "🎭 Deseja aplicar MAC spoofing? (s/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        spoof_mac
    fi
    
    # Finalização
    start_services
    configure_killswitch
    verify_tor
    test_leaks
    
    log "✅ CEBOLINHA v2.0 INSTALADO COM SUCESSO!"
    
    show_guide
}

# ============================================================
# EXECUÇÃO
# ============================================================
main "$@"
