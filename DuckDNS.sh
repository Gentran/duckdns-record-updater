#!/usr/bin/bash
shopt -s lastpipe
cd $(dirname `readlink -f $0`)
IPconf='IPaddress.conf'
#配置文件存在且不为空则读取存储的IPv4和IPv6值
[ -s $IPconf ] && source $IPconf
#输入电信光猫的用户密码
cookiejar=`curl --silent 'http://192.168.1.1/cgi-bin/luci' --data 'username=useradmin&psd=密码' --cookie-jar -`
curIPv4=`curl --silent 'http://192.168.1.1/cgi-bin/luci/admin/settings/gwinfo?get=part' --cookie - <<< $cookiejar | awk -F ',' '{gsub(/"/,"",$4);split($4,t,/:/);print t[2]}'`
curl --silent 'http://192.168.1.1/cgi-bin/luci/admin/logout' --cookie - <<< $cookiejar
curIPv6=`ip -6 addr show eth0 scope global -deprecated -temporary | awk '/inet6/{gsub(/\/.*/, "", $2); print $2}'`

if [ "$1" = "--showIP" ];then
  echo -e "IPv4: $curIPv4"
  for i in $curIPv6;do
    echo IPv6: $i
  done
  exit
fi

if [ $IPv6 ];then
    [[ $curIPv6 =~ $IPv6 ]] && curIPv6=$IPv6 
else
    curIPv6=`awk 'NR==1' <<< $curIPv6`
fi

#在此配置你的DuckDNS子域和token
domain='myhome'
token='11111111-1111-1111-1111-11111111'
url="https://www.duckdns.org/update?domains=$domain&token=$token"

[ "$curIPv6" != "$IPv6" ] && url+='&ipv6='$curIPv6
if ! [[ $curIPv4 =~ ^100?\. ]];then
  [ "$curIPv4" != "$IPv4" ] && url+='&ip='$curIPv4
fi

inet=`grep -o 'ip\w*' <<< $url`
[ $? != 0 ] && echo 'No need to update!' && exit 0
if [ `wc -l <<< $inet` -eq 2 ];then
  inet='IPv4 & IPv6'
fi
echo -n "Updating $inet record..." && curl --silent --show-error $url && echo -e "IPv4=$curIPv4\nIPv6=$curIPv6" > $IPconf
