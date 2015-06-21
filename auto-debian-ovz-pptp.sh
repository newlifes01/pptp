#!/bin/bash 
2 # Interactive PoPToP install script for an OpenVZ VPS 
3 # Tested on Debian 5, 6, and Ubuntu 11.04 
4 
 
5 echo "######################################################" 
6 echo "Interactive PoPToP Install Script for an OpenVZ VPS" 
7 echo 
8 echo "Make sure to contact your provider and have them enable" 
9 echo "IPtables and ppp modules prior to setting up PoPToP." 
10 echo "PPP can also be enabled from SolusVM." 
11 echo 
12 echo "You need to set up the server before creating more users." 
13 echo "A separate user is required per connection or machine." 
14 echo "######################################################" 
15 echo 
16 echo 
17 echo "######################################################" 
18 echo "Select on option:" 
19 echo "1) Set up new PoPToP server AND create one user" 
20 echo "2) Create additional users" 
21 echo "######################################################" 
22 read x 
23 if test $x -eq 1; then 
24 	echo "Enter username that you want to create (eg. client1 or john):" 
25 	read u 
26 	echo "Specify password that you want the server to use:" 
27 	read p 
28 
 
29 # get the VPS IP 
30 ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://` 
31 
 
32 echo 
33 echo "######################################################" 
34 echo "Downloading and Installing PoPToP" 
35 echo "######################################################" 
36 apt-get update 
37 apt-get -y install pptpd 
38 
 
39 echo 
40 echo "######################################################" 
41 echo "Creating Server Config" 
42 echo "######################################################" 
43 cat > /etc/ppp/pptpd-options <<END 
44 name pptpd 
45 refuse-pap 
46 refuse-chap 
47 refuse-mschap 
48 require-mschap-v2 
49 require-mppe-128 
50 ms-dns 8.8.8.8 
51 ms-dns 8.8.4.4 
52 proxyarp 
53 nodefaultroute 
54 lock 
55 nobsdcomp 
56 END 
57 
 
58 # setting up pptpd.conf 
59 echo "option /etc/ppp/pptpd-options" > /etc/pptpd.conf 
60 echo "logwtmp" >> /etc/pptpd.conf 
61 echo "localip $ip" >> /etc/pptpd.conf 
62 echo "remoteip 10.1.0.1-100" >> /etc/pptpd.conf 
63 
 
64 # adding new user 
65 echo "$u	*	$p	*" >> /etc/ppp/chap-secrets 
66 
 
67 echo 
68 echo "######################################################" 
69 echo "Forwarding IPv4 and Enabling it on boot" 
70 echo "######################################################" 
71 cat >> /etc/sysctl.conf <<END 
72 net.ipv4.ip_forward=1 
73 END 
74 sysctl -p 
75 
 
76 echo 
77 echo "######################################################" 
78 echo "Updating IPtables Routing and Enabling it on boot" 
79 echo "######################################################" 
80 iptables -t nat -A POSTROUTING -j SNAT --to $ip 
81 # saves iptables routing rules and enables them on-boot 
82 iptables-save > /etc/iptables.conf 
83 
 
84 cat > /etc/network/if-pre-up.d/iptables <<END 
85 #!/bin/sh 
86 iptables-restore < /etc/iptables.conf 
87 END 
88 
 
89 chmod +x /etc/network/if-pre-up.d/iptables 
90 cat >> /etc/ppp/ip-up <<END 
91 ifconfig ppp0 mtu 1400 
92 END 
93 
 
94 echo 
95 echo "######################################################" 
96 echo "Restarting PoPToP" 
97 echo "######################################################" 
98 sleep 5 
99 /etc/init.d/pptpd restart 
100 
 
101 echo 
102 echo "######################################################" 
103 echo "Server setup complete!" 
104 echo "Connect to your VPS at $ip with these credentials:" 
105 echo "Username:$u ##### Password: $p" 
106 echo "######################################################" 
107 
 
108 # runs this if option 2 is selected 
109 elif test $x -eq 2; then 
110 	echo "Enter username that you want to create (eg. client1 or john):" 
111 	read u 
112 	echo "Specify password that you want the server to use:" 
113 	read p 
114 
 
115 # get the VPS IP 
116 ip=`ifconfig venet0:0 | grep 'inet addr' | awk {'print $2'} | sed s/.*://` 
117 
 
118 # adding new user 
119 echo "$u	*	$p	*" >> /etc/ppp/chap-secrets 
120 
 
121 echo 
122 echo "#####################TopMyHosting.com######################" 
123 echo "Addtional user added!" 
124 echo "Connect to your VPS at $ip with these credentials:" 
125 echo "Username:$u ##### Password: $p" 
126 echo "######################TopMyHosting.com####################" 
127 
 
128 else 
129 echo "Invalid selection, quitting." 
130 exit 
131 fi 
