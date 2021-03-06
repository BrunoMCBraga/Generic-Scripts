# Set default chain policies 
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

ip6tables -P INPUT DROP
ip6tables -P FORWARD DROP
ip6tables -P OUTPUT DROP

# Delete rules, chains and zero counters
iptables -Z
iptables -F
iptables -X

ip6tables -Z
ip6tables -F
ip6tables -X

# Allow localhost activity 
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

ip6tables -A INPUT -i lo -j ACCEPT
ip6tables -A OUTPUT -o lo -j ACCEPT

# Inbound whitelist
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
ip6tables -A INPUT -p tcp --dport 22 -j ACCEPT

# Allow established sessions to receive traffic (inbound and outbound)
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
ip6tables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A OUTPUT -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT
ip6tables -A OUTPUT -m conntrack --ctstate NEW,ESTABLISHED,RELATED -j ACCEPT

   
# Persisting and restarting
iptables-save > /etc/sysconfig/iptables
systemctl enable iptables.service
systemctl restart iptables.service

ip6tables-save > /etc/sysconfig/ip6tables
systemctl enable ip6tables.service
systemctl restart ip6tables.service
