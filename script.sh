#!/bin/bash
sudo su
yum update -y
yum -y install openldap compat-openldap openldap-clients openldap-servers openldap-servers-sql openldap-devel
systemctl start slapd
systemctl enable slapd
slappasswd -s parol > PASS

cat > ldaprootpasswd.ldif <<EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $(cat PASS)
EOF

ldapmodify -Y EXTERNAL -H ldapi:/// -f ldaprootpasswd.ldif
cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
chown -R ldap:ldap /var/lib/ldap
systemctl restart slapd

ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat > ldapdomain.ldif <<EOF
dn: olcDatabase={1}monitor,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=Manager,dc=devopsldab,dc=com" read by * none
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcSuffix
olcSuffix: dc=devopsldab,dc=com
dn: olcDatabase={2}hdb,cn=config
changetype: modify
replace: olcRootDN
olcRootDN: cn=Manager,dc=devopsldab,dc=com
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $(cat temp)
dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=devopsldab,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=devopsldab,dc=com" write by * read
EOF

ldapadd -Y EXTERNAL -H ldapi:/// -f ldapdomain.ldif

cat > baseldapdomain.ldif <<EOF
dn: dc=devopsldab,dc=com
objectClass: top
objectClass: dcObject
objectclass: organization
o: devopsldab com
dc: devopsldab
dn: cn=Manager,dc=devopsldab,dc=com
objectClass: organizationalRole
cn: Manager
description: Directory Manager
dn: ou=People,dc=devopsldab,dc=com
objectClass: organizationalUnit
ou: People
dn: ou=Group,dc=devopsldab,dc=com
objectClass: organizationalUnit
ou: Group
EOF

ldapadd -x -w parol -D "cn=Manager,dc=devopsldab,dc=com" -f baseldapdomain.ldif

cat > ldapgroup.ldif <<EOF
dn: cn=Manager,ou=Group,dc=devopsldab,dc=com
objectClass: top
objectClass: posixGroup
gidNumber: 1005
EOF

ldapadd -x -w parol -D "cn=Manager,dc=devopsldab,dc=com" -f ldapgroup.ldif

cat > ldapuser.ldif <<EOF
dn: uid=my_user,ou=People,dc=devopsldab,dc=com
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
cn: my_user
uid: my_user
uidNumber: 1005
gidNumber: 1005
homeDirectory: /home/my_user
userPassword: $(cat PASS)
loginShell: /bin/bash
gecos: my_user
shadowLastChange: 0
shadowMax: -1
shadowWarning: 0
EOF

ldapadd -x -w parol -D "cn=Manager,dc=devopsldab,dc=com" -f ldapuser.ldif

rm -f PASS

yum install -y phpldapadmin
sed -i '397 s;// $servers;$servers;' /etc/phpldapadmin/config.php
sed -i '398 s;$servers->setValue;// $servers->setValue;' /etc/phpldapadmin/config.php
sed -i ' s;Require local;Require all granted;' /etc/httpd/conf.d/phpldapadmin.conf
sed -i ' s;Allow from 127.0.0.1;Allow from 0.0.0.0;' /etc/httpd/conf.d/phpldapadmin.conf
systemctl restart httpd
