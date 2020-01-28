# GitOps with ArgoCD on OpenShift 4

Install ArgoCD and some resources to demonstrate GitOps concepts and how they relate to OpenShift.

Based on [this GitOps blog post](https://blog.openshift.com/introduction-to-gitops-with-openshift/) from the [OpenShift blog](https://blog.openshift.com).

Unlike the blog post, this will install ArgoCD based on the [ArgoCD Operator](https://github.com/argoproj-labs/argocd-operator) that is in development.

## Run the Setup Script

Run `./setup.sh` and answer the following questions:
* Apps base domain (e.g. apps.example.com, or apps-crc.testing)
* Github URL - the URL of your fork of this repository (e.g https://github.com/username/gitops-argocd.git)
* Branch - A new branch name to use, or master.
* Quay read/write account:
    * username:  A quay user with read and write to your quay repostiory
    * email:  email account for this user
    * password:  password for this user
* Quay read-only account (can be same as read-write):
    * username:  A quay user with read and write to your quay repostiory
    * email:  email account for this user
    * password:  password for this user


This will:
1. Update yaml files with your own github repo and branch, as well as update any routes with your cluster apps url.
2. Install ArgoCD into a new `argocd` namesapce and print the default admin password to the console.
3. Install Bitnami Sealed Secrets (using Argo CD that you just installed!) and download the public key to use with `kubeseal`.
4. Create some `SealedSecret` custom resources with your Quay credentials for use with Jenkins and for image pull secrets.
5. Commit and push all this to your github repo and branch.

Once this is done, your cluster will have Argo CD up and running as well as Bitnami Sealed Secrets.  You will also be ready to create more sealed secrets with `kubeseal`.

Woot!

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
