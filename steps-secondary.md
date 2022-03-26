```shell
NAMESPACE='vault'

kubectl create namespace ${NAMESPACE?}

secret=$(cat vault.hclic)
kubectl create secret --namespace=${NAMESPACE?} generic vault-ent-license --from-literal="license=${secret}"
```

Note: for the purposes of this example I added *.westus2.cloudapp.azure.com as a SAN to my certificate
```
kubectl create secret generic vault-server-tls \
        --namespace ${NAMESPACE?} \
        --from-file=vault.key=${TMPDIR}/vault.key \
        --from-file=vault.crt=${TMPDIR}/vault.crt \
        --from-file=vault.ca=${TMPDIR}/vault.ca

helm install vault-secondary \
  --namespace="${NAMESPACE?}" \
  -f values-secondary.yaml hashicorp/vault --version=0.19.0

kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-0 -- vault operator init -key-shares=1 -key-threshold=1
kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-0 -- vault operator unseal
```
Note, could use raft cloud auto join
```
kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-1 -- /bin/sh
export CA_CERT=`cat $VAULT_CACERT`
vault operator raft join -leader-ca-cert="$CA_CERT" "https://vault-secondary-0.vault-secondary-internal:8200"
vault operator unseal
exit

kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-2 -- /bin/sh
export CA_CERT=`cat $VAULT_CACERT`
vault operator raft join -leader-ca-cert="$CA_CERT" "https://vault-secondary-0.vault-secondary-internal:8200"
vault operator unseal
exit

kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-0 -- vault login

kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-0 -- vault operator raft list-peers
```

Specify the [primary_api_addr](https://www.vaultproject.io/api-docs/system/replication/replication-dr#primary_api_addr)
This should be the value of your vault-primary-active service external IP port 8200

Specify the [ca_file](https://www.vaultproject.io/api-docs/system/replication/replication-dr#ca_file)
IF these two clusters are using different CAs, then the ca_file of the primary cluster must be provided
```
kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-0 -- vault write sys/replication/dr/secondary/enable primary_api_addr=https://assareh-vault-pri.westus2.cloudapp.azure.com:8200 ca_file=/tmp/primary-ca.crt token=[DR SECONDARY ACTIVATION TOKEN FROM PRIMARY]
```

Last, delete the remainder secondary pods and unseal them using the primary unseal token after Kubernetes reschedules them:
```
kubectl --namespace=${NAMESPACE?} delete pod vault-secondary-1
kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-1 -- vault operator unseal <PRIMARY UNSEAL TOKEN>

kubectl --namespace=${NAMESPACE?} delete pod vault-secondary-2
kubectl --namespace=${NAMESPACE?} exec -ti vault-secondary-2 -- vault operator unseal <PRIMARY UNSEAL TOKEN>
```