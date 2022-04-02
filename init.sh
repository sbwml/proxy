#!/bin/sh

cat >/opt/v2ray/etc/config.json <<EOF
{
	"log": {
		"access": "/dev/null",
		"error": "/dev/null",
		"loglevel": "warning"
	},
	"inbounds": [{
			"port": 10000,
			"listen": "0.0.0.0",
			"protocol": "vmess",
			"settings": {
				"clients": [{
					"id": "$UUID",
					"alterId": 0
				}]
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "$VMESS"
				}
			}
		},
		{
			"port": 20000,
			"listen": "0.0.0.0",
			"protocol": "vless",
			"settings": {
				"clients": [{
					"id": "$UUID",
					"email": "vless@localhost.com"
				}],
				"decryption": "none"
			},
			"streamSettings": {
				"network": "ws",
				"wsSettings": {
					"path": "$VLESS"
				}
			}
		}
	],
	"outbounds": [{
		"protocol": "freedom",
		"settings": {}
	}],
	"dns": {
		"server": [
			"8.8.8.8",
			"8.8.4.4",
			"localhost"
		]
	}
}
EOF

cat >/etc/nginx/conf.d/default.conf <<EOF
server {
    listen        $PORT default_server;
    server_name   _;

    location $VMESS {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:10000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location $VLESS {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:20000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection upgrade;
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

/opt/v2ray/sbin/httpd -config /opt/v2ray/etc/config.json >/dev/null 2>&1 &
nginx -g 'daemon off;'
