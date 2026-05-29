Below are the commands for setting up Monitoring:

1. helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
2. helm repo update
3. kubectl get secret --namespace monitoring monitoring-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
4. kubectl port-forward -n monitoring svc/monitoring-stack-grafana 3000:80
