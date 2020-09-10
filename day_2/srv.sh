#!/bin/bash
sudo yum install openldap openldap-servers openldap-clients -y
sudo systemctl start slapd
sudo systemctl enable slapd
sudo firewall-cmd --add-service=ldap

PASS=`slappasswd -s tineproidzesh`

cat > ldaprootpasswd.ldif <<EOF
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: ${PASS}
EOF
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f ldaprootpasswd.ldif

sudo cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG
sudo chown -R ldap:ldap /var/lib/ldap/DB_CONFIG
sudo systemctl restart slapd
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif

cat > openssh-lpk.ldif <<EOF
dn: cn=openssh-lpk,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: openssh-lpk
olcAttributeTypes: ( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey'
    DESC 'MANDATORY: OpenSSH Public key'
    EQUALITY octetStringMatch
    SYNTAX 1.3.6.1.4.1.1466.115.121.1.40 )
olcObjectClasses: ( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' SUP top AUXILIARY
    DESC 'MANDATORY: OpenSSH LPK objectclass'
    MAY ( sshPublicKey $ uid )
    )
EOF
sudo ldapadd -Y EXTERNAL -H ldapi:/// -f openssh-lpk.ldif

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
olcRootPW: ${PASS}

dn: olcDatabase={2}hdb,cn=config
changetype: modify
add: olcAccess
olcAccess: {0}to attrs=userPassword,shadowLastChange by
  dn="cn=Manager,dc=devopsldab,dc=com" write by anonymous auth by self write by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by dn="cn=Manager,dc=devopsldab,dc=com" write by * read
EOF
sudo ldapmodify -Y EXTERNAL -H ldapi:/// -f ldapdomain.ldif

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
sudo ldapadd -x -D cn=Manager,dc=devopsldab,dc=com -w pass -f baseldapdomain.ldif

cat > ldapgroup.ldif <<EOF
dn: cn=Manager,ou=Group,dc=devopsldab,dc=com
objectClass: top
objectClass: posixGroup
gidNumber: 1005
EOF
sudo ldapadd -x -w pass -D "cn=Manager,dc=devopsldab,dc=com" -f ldapgroup.ldif

cat > ldapuser.ldif <<EOF
dn: uid=my_user,ou=People,dc=devopsldab,dc=com
objectClass: top
objectClass: account
objectClass: posixAccount
objectClass: shadowAccount
objectClass: ldapPublicKey
cn: my_user
uid: my_user
uidNumber: 1005
gidNumber: 1005
homeDirectory: /home/my_user
userPassword: ${PASS}
loginShell: /bin/bash
gecos: my_user
shadowLastChange: 0
shadowMax: -1
shadowWarning: 0
sshPublicKey: ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDo/30PdfTnoHDdhhKw+5CExocaEz7PobRDvxqNxFQxXUcPbwpib3p+7CyaCkJI8zXqvSkX+aUPA5mPms6gE+NU2qtFx2Uo8okkGHrXd0hKv6nmFu6FKWsnrm2scvNV7YBK58XtYUSuCdVRsF2VmPppSI6teQwEKXNV0tOCqyVVHumZR+WP/QeeU4cLy9BsJp1XHVv2Q+5HC/RZnaIGzIgbtxSmd9+eZMIEioLkZ50UxceZCLI37X9t6ScF5Sf7G5ozUpyOOu0dTBubJXBwA5tv7+IHs0t67J1qqHuOUUSP0EfxrYN693n+vYIjXLudjRN4E3HJNfJKan6eXiEYkG8T root@epam-lab
EOF
sudo ldapadd -x -D cn=Manager,dc=devopsldab,dc=com -w pass -f  ldapuser.ldif


sudo yum --enablerepo=epel -y install phpldapadmin
sudo sed -i '397 s@//@  @' /etc/phpldapadmin/config.php
sudo sed -i '398 s@^@//@' /etc/phpldapadmin/config.php
sudo sed -i 's/Require local/require all granted/' /etc/httpd/conf.d/phpldapadmin.conf
sudo systemctl restart httpd
rm -f *.ldif 
