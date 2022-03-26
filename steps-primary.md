```shell
NAMESPACE='vault'

helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

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

helm install vault-primary \
  --namespace="${NAMESPACE?}" \
  -f values-primary.yaml hashicorp/vault --version=0.19.0

kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault operator init -key-shares=1 -key-threshold=1
kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault operator unseal
```
Note, could use raft cloud auto join
```
kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-1 -- /bin/sh
export CA_CERT=`cat $VAULT_CACERT`
vault operator raft join -leader-ca-cert="$CA_CERT" "https://vault-primary-0.vault-primary-internal:8200"
vault operator unseal
exit

kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-2 -- /bin/sh
export CA_CERT=`cat $VAULT_CACERT`
vault operator raft join -leader-ca-cert="$CA_CERT" "https://vault-primary-0.vault-primary-internal:8200"
vault operator unseal
exit

kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault login

kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault operator raft list-peers
```
Specify the [primary_cluster_addr](https://www.vaultproject.io/api-docs/system/replication/replication-dr#primary_cluster_addr)
This should be the value of your vault-primary-active service external IP port 8201

```
kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault write -f sys/replication/dr/primary/enable primary_cluster_addr=https://assareh-vault-pri.westus2.cloudapp.azure.com:8201

kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault read sys/replication/dr/status

kubectl --namespace=${NAMESPACE?} exec -ti vault-primary-0 -- vault write sys/replication/dr/primary/secondary-token id=secondary
```