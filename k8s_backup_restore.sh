#!/bin/bash

printf "> Configuring Minio S3 For Velero Backup And Restore Storage..."
echo " OK"
if [ $(docker ps |grep minio|wc -l) -lt 1 ];then
docker run -e  MINIO_ROOT_USER=admin -e MINIO_ROOT_PASSWORD=Strong#Pass# -d --name minio -p 9000:9000 -p 9001:9001 -v /minio:/data minio/minio server --console-address ":9001" /data
fi

printf "> Waiting for minio to be up and running.."
echo " OK"
sleep 30



printf "> Installing minio cli to create bucket.."
echo " OK"
if ! command -v mc > /dev/null 2>&1 ;then
sudo -v &> /dev/null && : || { echo "> You must have sudo access to run this script - Or please run this via root" ; exit 1 ; }
sudo curl -o /usr/local/bin/mc https://dl.min.io/client/mc/release/linux-amd64/mc
sudo chmod +x /usr/local/bin/mc
else
printf "> Skipping - velero tool is already install.."
echo " OK"
fi


printf "> Creating s3 bucket.."
BUCKET=subham
echo " OK"
mc alias set minio http://127.0.0.1:9000 admin Strong#Pass#
sleep 5
if [  $(mc ls minio|grep $BUCKET|wc -l) -lt 1 ];then
mc mb minio/$BUCKET
else
printf "> $BUCKET already exist - Skipping.."
echo " OK"
fi

printf "> Installing Velero.."
echo " OK"
if ! command -v velero > /dev/null 2>&1 ;then
sudo -v &> /dev/null && : || { echo "> You must have sudo access to run this script - Or please run this via root" ; exit 1 ; }
wget https://github.com/heptio/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar zxf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/
rm -rf velero*
else
printf "> Skipping - velero tool is already install.."
echo " OK"
fi


printf "> Configuring Velero in K8s cluster..."
echo " OK"
mkdir -p ~/.minio
cat <<EOF>>  ~/.minio/minio.credentials
[default]
aws_access_key_id=admin
aws_secret_access_key=Strong#Pass#
EOF

velero install  \
      --provider aws --bucket subham   \
      --secret-file ~/.minio/minio.credentials  \
      --backup-location-config region=minio,s3ForcePathStyle=true,s3Url=http://$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1):9000 \
      --plugins velero/velero-plugin-for-aws:v1.0.0


printf "> Please Wait for velero to be up and running..."
echo " OK"
sleep 100



echo "> You can verify using below command"
echo "> velero backup-location get"


velero backup-location get


printf "> You can access minio UI via below URL- "
echo " OK"
eval echo "https://$(/sbin/ip -o -4 addr list eth1 | awk '{print $4}' | cut -d/ -f1):9001"
echo "OR"
eval echo "https://$(/sbin/ip -o -4 addr list eth0 | awk '{print $4}' | cut -d/ -f1):9001"

printf "> You can use below ID and Password to login in portal.."
echo " OK"
echo "> UserID - admin"
echo "> Password - Strong#Pass#"
