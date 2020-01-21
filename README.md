# GitOps with ArgoCD on OpenShift 4

Install ArgoCD and some resources to demonstrate GitOps concepts and how they relate to OpenShift.

Based on [this GitOps blog post](https://blog.openshift.com/introduction-to-gitops-with-openshift/) from the [OpenShift blog](https://blog.openshift.com).

Unlike the blog post, this will install ArgoCD based on the [ArgoCD Operator](https://github.com/argoproj-labs/argocd-operator) that is in development.

## Install ArgoCD Operator

For now, all the steps are distilled into `install-argocd-operator.sh`.  Running that script will install the operator, then install an Argo CD instance.

```
./install-argocd-operator.sh
```

Add the end of the script the initial Argo CD password should be printed to the terminal.  If you don't see a password, that's simply because the `argocd-server` pod hasn't started yet.  You can re-run the last `oc` command in the script to print the initial password.

When logging in with the CLI locally using CodeReady Containers (CRC), you need do some port forwarding:
```
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login 127.0.0.1:8080
```

## Install Bitnami SealedSecrets

[Bitnami Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) offer a safe way to encrypt and save secrets in your git repositories just like any other resource.  The only entity that can decrypt these secrets is the Sealed Secrets controller running in the cluster.

Installation takes a few steps in order to run on OpenShift.
```
# First, create the namespace for the SealedSecrets operator.
oc adm new-project openshift-secrets
oc project openshift-secrets

# Next, create the secret with the TLS certs for encrypting secrets.
# NEVER STORE THIS SECRET IN YOUR GIT REPO!  THIS IS ONLY A DEMO!
oc create -f deploy/sealedsecrets-secret.yaml

# Next, deploy the operator.
oc create -f deploy/sealedsecrets.yaml

# Finally, give the SealedSecrets service account anyuid, as it expects to run as 1001.
oc adm policy add-scc-to-user anyuid -z sealed-secrets-controller
```

Now you can automatically decrypt `SealedSecrets` into real `Secrets`.  Woot!

## Fork and Update the Repo

Fork this repository and clone it.  The `master` branch is setup to be a template branch for you to configure for your own cluster and git repository.

Once you are in your own repo and branch, execute the `new-env.sh` script to update the files to reflect your own environment:
```
./new-env.sh 
Base apps url (e.g. apps.ocp.pitt.ca): apps.ocp.mycluster.ca
Git repository url: https://github.com/pittar/gitops-argocd.git
Git branch (e.g. master): master
```

## Add Argo CD Projects and Applications

### Projects

First, install a few `projects`.  These are ArgoCD projects which is a nice way to organize Argo CD applications.
```
oc create -f gitops/projects -n argocd
```

To add CI/CD tools (Jenkins, SonarQube, Nexus):
```
oc create -f gitops/applications/cicd -n argocd
```

To install an example Java app that uses the CI/CD tools:
```
oc create -f gitops/applications/apps/petclinic -n argocd
```

To add CodeReady Workspaces:
```
oc create -f gitops/applications/codeready -n argocd
```
