#!/usr/bin/env bash

Add_Iptables_Rules()
{
    #add iptables firewall rules
    if command -v iptables >/dev/null 2>&1; then
        iptables -I INPUT 1 -i lo -j ACCEPT
        iptables -I INPUT 2 -m state --state ESTABLISHED,RELATED -j ACCEPT
        iptables -I INPUT 3 -p tcp --dport 22 -j ACCEPT
        iptables -I INPUT 4 -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT 5 -p tcp --dport 443 -j ACCEPT
        iptables -I INPUT 6 -p tcp --dport 3306 -j DROP
        iptables -I INPUT 7 -p icmp -m icmp --icmp-type 8 -j ACCEPT
        if [ "$PM" = "yum" ]; then
            yum -y install iptables-services
            service iptables save
            service iptables reload
            if command -v firewalld >/dev/null 2>&1; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
            StartUp iptables
        elif [ "$PM" = "apt" ]; then
            apt-get --no-install-recommends install -y iptables-persistent
            if [ -s /etc/init.d/netfilter-persistent ]; then
                /etc/init.d/netfilter-persistent save
                /etc/init.d/netfilter-persistent reload
                StartUp netfilter-persistent
            else
                /etc/init.d/iptables-persistent save
                /etc/init.d/iptables-persistent reload
                StartUp iptables-persistent
            fi
        fi
    fi
}

Add_nextLNMP_Startup()
{
    echo "Add Startup and Starting nextLNMP..."
    \cp ${cur_dir}/conf/nextlnmp /bin/nextlnmp
    chmod +x /bin/nextlnmp
    StartUp nginx
    StartOrStop start nginx
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/nextlnmp
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    elif [ "${DBSelect}" = "0" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/nextlnmp
    fi
    StartUp php-fpm
    StartOrStop start php-fpm
    if [ "${PHPSelect}" = "1" ]; then
        sed -i 's#/usr/local/php/var/run/php-fpm.pid#/usr/local/php/logs/php-fpm.pid#' /bin/nextlnmp
    fi
}

Add_nextLNMPA_Startup()
{
    echo "Add Startup and Starting nextLNMPA..."
    \cp ${cur_dir}/conf/nextlnmpa /bin/nextlnmp
    chmod +x /bin/nextlnmp
    StartUp nginx
    StartOrStop start nginx
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/nextlnmp
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    elif [ "${DBSelect}" = "0" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/nextlnmp
    fi
    StartUp httpd
    StartOrStop start httpd
}

Add_LAMP_Startup()
{
    echo "Add Startup and Starting NextLAMP..."
    \cp ${cur_dir}/conf/lamp /bin/nextlnmp
    chmod +x /bin/nextlnmp
    StartUp httpd
    StartOrStop start httpd
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        StartUp mariadb
        StartOrStop start mariadb
        sed -i 's#/etc/init.d/mysql#/etc/init.d/mariadb#' /bin/nextlnmp
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        StartUp mysql
        StartOrStop start mysql
    elif [ "${DBSelect}" = "0" ]; then
        sed -i 's#/etc/init.d/mysql.*##' /bin/nextlnmp
    fi
}

Check_Nginx_Files()
{
    isNginx=""
    echo "============================== Check install =============================="
    echo "Checking ..."
    if [[ -s /usr/local/nginx/conf/nginx.conf && -s /usr/local/nginx/sbin/nginx ]]; then
        Echo_Green "Nginx: OK"
        isNginx="ok"
    else
        Echo_Red "Error: Nginx install failed."
    fi
}

Check_DB_Files()
{
    isDB=""
    if [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        if [[ -s /usr/local/mariadb/bin/mysql && -s /usr/local/mariadb/bin/mysqld_safe && -s /etc/my.cnf ]]; then
            Echo_Green "MariaDB: OK"
            isDB="ok"
        else
            Echo_Red "Error: MariaDB install failed."
        fi
    elif [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        if [[ -s /usr/local/mysql/bin/mysql && -s /usr/local/mysql/bin/mysqld_safe && -s /etc/my.cnf ]]; then
            Echo_Green "MySQL: OK"
            isDB="ok"
        else
            Echo_Red "Error: MySQL install failed."
        fi
    elif [ "${DBSelect}" = "0" ]; then
        Echo_Green "Do not install MySQL/MariaDB."
        isDB="ok"
    fi
}

Check_PHP_Files()
{
    isPHP=""
    if [ "${Stack}" = "nextlnmp" ]; then
        if [[ -s /usr/local/php/sbin/php-fpm && -s /usr/local/php/etc/php.ini && -s /usr/local/php/bin/php ]]; then
            Echo_Green "PHP: OK"
            Echo_Green "PHP-FPM: OK"
            isPHP="ok"
        else
            Echo_Red "Error: PHP install failed."
        fi
    else
        if [[ -s /usr/local/php/bin/php && -s /usr/local/php/etc/php.ini ]]; then
            Echo_Green "PHP: OK"
            isPHP="ok"
        else
            Echo_Red "Error: PHP install failed."
        fi
    fi
}

Check_Apache_Files()
{
    isApache=""
    if [[ "${PHPSelect}" =~ ^[6789]|10$ ]]; then
        if [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/modules/libphp7.so && -s /usr/local/apache/conf/httpd.conf ]]; then
            Echo_Green "Apache: OK"
            isApache="ok"
        else
            Echo_Red "Error: Apache install failed."
        fi
    elif [[ "${PHPSelect}" =~ ^1[1-3]$ ]]; then
        if [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/modules/libphp.so && -s /usr/local/apache/conf/httpd.conf ]]; then
            Echo_Green "Apache: OK"
            isApache="ok"
        else
            Echo_Red "Error: Apache install failed."
        fi
    else
        if [[ -s /usr/local/apache/bin/httpd && -s /usr/local/apache/modules/libphp5.so && -s /usr/local/apache/conf/httpd.conf ]]; then
            Echo_Green "Apache: OK"
            isApache="ok"
        else
            Echo_Red "Error: Apache install failed."
        fi
    fi
}

Clean_DB_Src_Dir()
{
    echo "Clean database src directory..."
    if [[ "${DBSelect}" =~ ^(1|2|3|4|5|11)$ ]]; then
        rm -rf ${cur_dir}/src/${Mysql_Ver}
    elif [[ "${DBSelect}" =~ ^(6|7|8|9|10)$ ]]; then
        rm -rf ${cur_dir}/src/${Mariadb_Ver}
    fi
    if [[ "${DBSelect}" = "4" ]]; then
        [[ -d "${cur_dir}/src/${Boost_Ver}" ]] && rm -rf ${cur_dir}/src/${Boost_Ver}
    elif [[ "${DBSelect}" = "5" ]]; then
        [[ -d "${cur_dir}/src/${Boost_New_Ver}" ]] && rm -rf ${cur_dir}/src/${Boost_New_Ver}
    fi
}

Clean_PHP_Src_Dir()
{
    echo "Clean PHP src directory..."
    rm -rf ${cur_dir}/src/${Php_Ver}
}

Clean_Web_Src_Dir()
{
    echo "Clean Web Server src directory..."
    if [ "${Stack}" = "nextlnmp" ]; then
        rm -rf ${cur_dir}/src/${Nginx_Ver}*
    elif [ "${Stack}" = "nextlnmpa" ]; then
        rm -rf ${cur_dir}/src/${Nginx_Ver}*
        rm -rf ${cur_dir}/src/${Apache_Ver}
    elif [ "${Stack}" = "lamp" ]; then
        rm -rf ${cur_dir}/src/${Apache_Ver}
    fi
    [[ -d "${cur_dir}/src/${Openssl_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_Ver}
    [[ -d "${cur_dir}/src/${Openssl_New_Ver}" ]] && rm -rf ${cur_dir}/src/${Openssl_New_Ver}
    [[ -d "${cur_dir}/src/${Pcre_Ver}" ]] && rm -rf ${cur_dir}/src/${Pcre_Ver}
    [[ -d "${cur_dir}/src/${LuaNginxModule}" ]] && rm -rf ${cur_dir}/src/${LuaNginxModule}
    [[ -d "${cur_dir}/src/${NgxDevelKit}" ]] && rm -rf ${cur_dir}/src/${NgxDevelKit}
    [[ -d "${cur_dir}/src/${NgxFancyIndex_Ver}" ]] && rm -rf ${cur_dir}/src/${NgxFancyIndex_Ver}
}

Print_Sucess_Info()
{
    Clean_Web_Src_Dir
    local SERVER_IP=$(hostname -I | awk '{print $1}')
    echo ""
    Echo_Green "╔══════════════════════════════════════════════════════════════╗"
    Echo_Green "║                                                              ║"
    Echo_Green "║        nextLNMP V${NEXTLNMP_Ver} 安装成功！                  ║"
    Echo_Green "║        系统：${DISTRO} Linux · 作者：静水流深                ║"
    Echo_Green "║                                                              ║"
    Echo_Green "╠══════════════════════════════════════════════════════════════╣"
    echo "║"
    echo "║  📦 服务管理："
    echo "║     nextlnmp {start|stop|restart|reload|status}"
    echo "║"
    echo "║  🌐 Web 访问："
    echo "║     探针页面：http://${SERVER_IP}/p.php"
    echo "║     phpMyAdmin：http://${SERVER_IP}/phpmyadmin/"
    echo "║     PHP 信息：http://${SERVER_IP}/phpinfo.php"
    echo "║"
    echo "║  📁 网站目录：${Default_Website_Dir}"
    echo "║  🔧 添加站点：nextlnmp vhost add"
    if [ "${DBSelect}" != "0" ]; then
        echo "║"
        echo "║  🔑 数据库 root 密码：${DB_Root_Password}"
        echo "║     查看密码：nextlnmp password"
        echo "║     记住后删除：nextlnmp password --delete"
    fi
    echo "║"
    echo "║  📖 文档：https://nextlnmp.com"
    echo "║  💬 QQ群：615298"
    Echo_Green "║                                                              ║"
    Echo_Green "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    nextlnmp status
    if command -v ss >/dev/null 2>&1; then
        ss -ntl
    else
        netstat -ntl
    fi
    stop_time=$(date +%s)
    echo ""
    Echo_Green "✅ 安装完成！耗时 $(((stop_time-start_time)/60)) 分钟"
}

Print_Failed_Info()
{
    if [ -s /bin/nextlnmp ]; then
        rm -f /bin/nextlnmp
    fi
    echo ""
    Echo_Red "╔══════════════════════════════════════════════════════════════╗"
    Echo_Red "║            ❌ nextLNMP 安装失败                             ║"
    Echo_Red "╚══════════════════════════════════════════════════════════════╝"
    Echo_Red "请将安装日志反馈给我们："
    Echo_Red "  日志文件：/root/nextlnmp-install.log"
    Echo_Red "  反馈地址：https://nextlnmp.com"
    Echo_Red "  QQ群：615298"
}

Check_nextLNMP_Install()
{
    Check_Nginx_Files
    Check_DB_Files
    Check_PHP_Files
    if [[ "${isNginx}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok" ]]; then
        Print_Sucess_Info
    else
        Print_Failed_Info
    fi
}

Check_nextLNMPA_Install()
{
    Check_Nginx_Files
    Check_DB_Files
    Check_PHP_Files
    Check_Apache_Files
    if [[ "${isNginx}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok"  &&"${isApache}" = "ok" ]]; then
        Print_Sucess_Info
    else
        Print_Failed_Info
    fi
}

Check_LAMP_Install()
{
    Check_Apache_Files
    Check_DB_Files
    Check_PHP_Files
    if [[ "${isApache}" = "ok" && "${isDB}" = "ok" && "${isPHP}" = "ok" ]]; then
        Print_Sucess_Info
    else
        Print_Failed_Info
    fi
}
