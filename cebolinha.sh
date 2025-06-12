#!/bin/bash

# /*********************************************************************************
# * Projeto:   Cebolinha
# * Autor:     Carlos Henrique Tourinho Santana
# * Versão:    1.0
# * Data:      12 de junho de 2025
# *
# * Descrição:
# * Este script realiza a instalação e configuração permanente de um sistema
# * para que TODO o seu tráfego de internet seja roteado através da rede Tor.
# * O design foca em uma execução "ponta a ponta" sem necessidade de qualquer
# * intervenção do usuário, transformando um sistema Debian/Ubuntu padrão
# * em uma máquina com privacidade aprimorada, similar ao Tails OS.
# *
# * Funcionalidades Principais:
# * - Execução Única: Configura o sistema de forma permanente com um único comando.
# * - Segurança por Padrão: Roteia todo o tráfego TCP e as consultas DNS
# * pela rede Tor, bloqueando outros tipos de tráfego para evitar vazamentos.
# * - Configuração Inteligente: Instala todas as dependências, configura
# * automaticamente o Tor para operar como proxy transparente e ajusta o
# * firewall do sistema de forma persistente.
# * - Robusto e à Prova de Falhas: O script para imediatamente se um erro ocorre,
# * verifica privilégios de root e garante que os serviços sejam iniciados e
# * habilitados na ordem correta.
# *
# * AVISO:
# * Esta é uma alteração significativa e permanente no funcionamento da rede
# * do seu sistema. Após a execução, sua conexão pode ficar mais lenta e
# * alguns sites ou serviços que bloqueiam o Tor podem se tornar inacessíveis.
# * Não há um comando de "desfazer" neste script.
# *********************************************************************************/


# --------------------------------------------------------------------------------------
# SEÇÃO 1: PREPARAÇÃO E VERIFICAÇÕES DE SEGURANÇA
# --------------------------------------------------------------------------------------

# Garante que o script pare imediatamente se qualquer comando retornar um erro.
set -e

# Garante que o script seja executado com privilégios de superusuário (root).
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ ERRO: Este script precisa ser executado com privilégios de root."
  echo "   Por favor, salve o arquivo como 'cebolinha.sh' e tente novamente usando: sudo ./cebolinha.sh"
  exit 1
fi


# --------------------------------------------------------------------------------------
# SEÇÃO 2: VARIÁVEIS DE CONFIGURAÇÃO
# --------------------------------------------------------------------------------------

# Porta do proxy transparente do Tor
TRANS_PORT="9040"

# Porta de DNS do Tor
DNS_PORT="5353"

# Endereços de rede local que NÃO devem passar pelo Tor (essencial para não quebrar a rede local)
NON_TOR_NETWORKS=("127.0.0.0/8" "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16")


# --------------------------------------------------------------------------------------
# SEÇÃO 3: EXECUÇÃO DA CONFIGURAÇÃO
# --------------------------------------------------------------------------------------

echo "🚀 INICIANDO A CONFIGURAÇÃO PERMANENTE DO SISTEMA PARA USAR A REDE TOR..."
sleep 3

# ETAPA 1: ATUALIZAÇÃO E INSTALAÇÃO DE DEPENDÊNCIAS
echo "🔄 [ETAPA 1/5] Atualizando o sistema e instalando dependências (tor, iptables-persistent)..."
apt-get update
# Pré-configura o `iptables-persistent` para não fazer perguntas durante a instalação.
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
apt-get install -y tor iptables-persistent

# ETAPA 2: CONFIGURAÇÃO DO SERVIÇO TOR
echo "⚙️  [ETAPA 2/5] Configurando o Tor para operar como proxy transparente..."
# Adiciona as linhas necessárias ao arquivo de configuração do Tor, caso não existam.
grep -qxF "VirtualAddrNetworkIPv4 10.192.0.0/10" /etc/tor/torrc || echo "VirtualAddrNetworkIPv4 10.192.0.0/10" >> /etc/tor/torrc
grep -qxF "AutomapHostsOnResolve 1" /etc/tor/torrc || echo "AutomapHostsOnResolve 1" >> /etc/tor/torrc
grep -qxF "TransPort ${TRANS_PORT}" /etc/tor/torrc || echo "TransPort ${TRANS_PORT}" >> /etc/tor/torrc
grep -qxF "DNSPort ${DNS_PORT}" /etc/tor/torrc || echo "DNSPort ${DNS_PORT}" >> /etc/tor/torrc

# ETAPA 3: CONFIGURAÇÃO DO FIREWALL (IPTABLES)
echo "🔥 [ETAPA 3/5] Criando regras de firewall para redirecionar todo o tráfego para o Tor..."

# Obtém o ID do usuário do sistema 'debian-tor' para criar exceções no firewall.
TOR_UID=$(id -u debian-tor)

# Limpa todas as regras existentes para começar do zero.
iptables -F
iptables -t nat -F

# --- Regras da Tabela NAT (Redirecionamento) ---
# Redireciona todas as consultas DNS (TCP/UDP, porta 53) para a porta DNS do Tor.
iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port ${DNS_PORT}
iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-port ${DNS_PORT}

# Cria exceções para o tráfego que não deve passar pelo Tor.
# 1. Tráfego gerado pelo próprio usuário do Tor (evita loops infinitos).
iptables -t nat -A OUTPUT -m owner --uid-owner $TOR_UID -j RETURN
# 2. Tráfego destinado à rede local (acesso ao roteador, outras máquinas na rede, etc.).
for net in "${NON_TOR_NETWORKS[@]}"; do
    iptables -t nat -A OUTPUT -d "$net" -j RETURN
done

# Redireciona todo o tráfego TCP restante para a porta de proxy transparente do Tor.
iptables -t nat -A OUTPUT -p tcp --syn -j REDIRECT --to-port ${TRANS_PORT}

# --- Regras da Tabela FILTER (Bloqueio de Vazamentos) ---
# Aceita o tráfego do usuário 'tor' e o tráfego de loopback.
iptables -A OUTPUT -m owner --uid-owner $TOR_UID -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT
# Bloqueia (REJECT) qualquer outro tráfego de saída que não foi redirecionado.
# Isso previne que tráfego UDP, ICMP, etc., vaze sua identidade.
iptables -A OUTPUT -j REJECT

# ETAPA 4: PERSISTÊNCIA DAS REGRAS DO FIREWALL
echo "💾 [ETAPA 4/5] Salvando as regras do firewall para que sejam permanentes..."
# O pacote `iptables-persistent` garante que este arquivo seja carregado na inicialização.
iptables-save > /etc/iptables/rules.v4
ip6tables-save > /etc/iptables/rules.v6

# ETAPA 5: FINALIZAÇÃO E REINICIALIZAÇÃO DOS SERVIÇOS
echo "🚀 [ETAPA 5/5] Habilitando e reiniciando os serviços para aplicar todas as mudanças..."
systemctl restart tor
systemctl enable tor # Garante que o Tor inicie com o sistema.

# --------------------------------------------------------------------------------------
# SEÇÃO 4: MENSAGEM DE SUCESSO E INFORMAÇÕES FINAIS
# --------------------------------------------------------------------------------------
echo ""
echo "=================================================================================="
echo "✅  S U C E S S O ! O seu sistema foi configurado pelo script Cebolinha."
echo "=================================================================================="
echo ""
echo "O seu computador agora roteia todo o tráfego de internet através do Tor."
echo "Esta configuração é PERMANENTE e será reativada a cada reinicialização."
echo ""
echo "Para verificar se está funcionando, você pode checar seu endereço de IP público."
echo "Ele deve ser diferente do seu IP real. Use o comando no terminal:"
echo "   curl https://check.torproject.org/api/ip"
echo ""
echo "=================================================================================="
echo "⚠️  LEMBRE-SE: Sua navegação será mais anônima, mas também mais lenta.        ⚠️"
echo "⚠️  Alguns serviços podem não funcionar corretamente através da rede Tor.         ⚠️"
echo "=================================================================================="
echo ""