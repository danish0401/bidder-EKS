## Connect Kubectl with EKS

> In order to use EKS Cluster for Bidder Deployment, connect kubectl cli with EKS Cluster.

* Check the current identity to verify that you're using the correct credentials that have permissions for the Amazon EKS cluster: <br />
`aws sts get-caller-identity`

* Create or update the kubeconfig file for your cluster: <br />
`aws eks --region us-east-1 update-kubeconfig --name Bidder-Test`

* Test your configuration: <br />
  `kubectl get svc`

## Deploy Bidder Application on EKS

> Once we are able to communicate with EKS, we can deploy bidder using the following commands

* Deploy Bidder application in the respective namespace using the following command: <br />
`kubectl apply -f bidder.yaml -n=spotx2 `
<br />
This will deploy bidder application in `spotx2` namespace.

* Check if pods are created in `spotx2` namespace: <br />
`kubectl get pods -n=spotx2`

* Exec into the container: <br />
  `kubectl exec -it pod_name -n=spotx2 -c bidder -- /bin/sh`

* Check logs of bidder container: <br />
  `kubectl logs pod_name -n=spotx2 -c bidder`

## Install Bidder helm charts on EKS

* Install bidder helm chart in respective name space: <br />
`helm install -f Helm/spotx2values.yaml spotx2 ./Helm/ -n spotx2 `
<br />
This will install bidder helmChart in `spotx2` namespace.

* Check if pods are created in `spotx2` namespace: <br />
`kubectl get pods -n=spotx2`

* Exec into the container: <br />
  `kubectl exec -n spotx2 --stdin --tty pod/pod_name -- /bin/bash`

* Check logs of bidder container: <br />
  `kubectl logs pod/pod_name -n spotx2`