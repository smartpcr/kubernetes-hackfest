
$gitRootFolder = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
while (-not (Test-Path (Join-Path $gitRootFolder ".git"))) {
    $gitRootFolder = Split-Path $gitRootFolder -Parent
}
$labFolder = Join-Path $gitRootFolder "labs"
if (-not (Test-Path $labFolder)) {
    throw "Invalid labs folder '$labFolder'"
}
$promFolder = "$labFolder\monitoring-logging\prometheus-grafana"
Set-Location $promFolder
$promRbacYamlFile = Join-Path $promFolder "prom-rbactillerconfig.yaml"
kubectl.exe apply -f $promRbacYamlFile

# Add the Core OS Helm Reop in case it is not already installed
helm.exe repo add coreos https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/
# Create a new Monitoring Namespace to deploy Prometheus Operator too
kubectl.exe create namespace monitoring
# Install Prometheus Operator
# NOTE: The output of this command will say failed because there is a job (pod)
# running and it takes a while to complete. It is ok, proceed to next step.
helm.exe install coreos/prometheus-operator --version 0.0.27 --name prometheus-operator --namespace monitoring
kubectl.exe -n monitoring get all -l "release=prometheus-operator"
# Install Prometheus Configuration and Setup for Kubernetes
helm.exe install coreos/kube-prometheus --version 0.0.95 --name kube-prometheus --namespace monitoring
kubectl.exe -n monitoring get all -l "release=kube-prometheus"
# Check to see that all the Pods are running
kubectl.exe get pods -n monitoring
# Other Useful Prometheus Operator Resources to Peruse
kubectl.exe get prometheus -n monitoring
kubectl.exe get prometheusrules -n monitoring
kubectl.exe get servicemonitor -n monitoring
kubectl.exe get cm -n monitoring
kubectl.exe get secrets -n monitoring

# Edit kubelet to be http instead of https (Fixes Prometheus kubelet API Metrics)
# Edit kube-dns to update Prometheus ENV (Fixes DNS API Metrics)
# https://github.com/coreos/prometheus-operator/issues/1522
kubectl.exe edit servicemonitors kube-prometheus-exporter-kubelets -n monitoring
$kubeDnsMetricsPatch = Get-Content (Join-Path $promFolder "prom-graf-kube-dns-metrics-patch.yaml") -Encoding Ascii
kubectl.exe patch deployment kube-dns-v20 -n kube-system --patch $kubeDnsMetricsPatch

# use your VI skills to change the below snippet. It should be "LoadBalancer" and not "ClusterIP"
kubectl.exe edit service kube-prometheus -n monitoring
kubectl.exe edit service kube-prometheus-alertmanager -n monitoring
kubectl.exe edit service kube-prometheus-grafana -n monitoring
kubectl.exe get service kube-prometheus -n monitoring
kubectl.exe get service kube-prometheus-alertmanager -n monitoring

# 1. Use ACR Build to create Container and Push to ACR
# 2. Update Container Image in Deployment manifest (prom-graf-sample-go-app.yaml) 
# Deploy the Sample GO Application with Updated Container Image
kubectl.exe create namespace sample-app 
kubectl.exe apply -f .\prom-graf-sample-go-app.yaml -n sample-app
# Deploy the ServiceMonitor to Monitor the Sample GO App
kubectl.exe apply -f .\prom-graf-servicemonitor.yaml -n monitoring
# Deploy the ConfigMap to Raise Alerts for the Sample GO App
kubectl.exe apply -f .\prom-graf-configmap.yaml -n monitoring