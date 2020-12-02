err(){
    clear && echo $1 && exit 1
}

check_root(){
    [[ $EUID != 0 ]] && err "ROOT is required"
}

download_trojan(){
    # GitHub: https://github.com/trojan-gfw/trojan-quickstart
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/trojan-gfw/trojan-quickstart/master/trojan-quickstart.sh)"
}

http_server(){
    mkdir .fakeweb
    echo It works! > .fakeweb/index.html
    curl -fsSL https://github.com/McDull-GitHub/go-http-server/releases/download/v1.0/http_linux_amd64 -o http
    chmod +x http
    nohup ./http -d .fakeweb &
}

cert(){
    mkdir /etc/.cert
    curl  https://get.acme.sh | sh
    ~/.acme.sh/acme.sh --issue -d $domain --webroot  ~/.fakeweb
    ~/.acme.sh/acme.sh --installcert -d $domain --key-file /etc/.cert/key.pem --fullchain-file /etc/.cert/cert.pem || err "證書申請有問題"
    test -f /etc/.cert/key.pem && test -f /etc/.cert/cert.pem || err "證書有問題"
}

config(){
    sed -i "s#/path/to/certificate.crt#/etc/.cert/cert.pem#g" /usr/local/etc/trojan/config.json
    sed -i "s#/path/to/private.key#/etc/.cert/key.pem#g" /usr/local/etc/trojan/config.json
    sed -i "s#password2#$password#g" /usr/local/etc/trojan/config.json
    sed -i 's#"password1",##g' /usr/local/etc/trojan/config.json
}

run_trojan(){
    systemctl restart trojan
}

show_config(){
    echo -e "Domain\t\t-->\t$domain"
    echo -e "Password\t-->\t$password"
    echo -e "Link\t\t-->\ttrojan://$password@$domain:443"
}

[[ "$2" == "" ]] &&  echo -e "Usage:\n\t trojan.sh [domian] [password]" && exit 0
domain=$1
password=$2
clear
check_root
download_trojan
http_server
cert
config
run_trojan
show_config
