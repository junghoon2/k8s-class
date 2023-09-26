# Amazon EKS Network Policy Demo (Stars)

The demo reuses Stars policy demo provided by the Project Calico. The demo creates a front-end, back-end, and client service on your Amazon EKS cluster. The demo also creates a management graphical user interface that shows the available ingress and egress paths between each service. We recommend that you complete the demo on a cluster that you don't run production workloads on.

## Prerequisites

To create a Kubernetes cluster which supports the Kubernetes network policy, please refer [Amazon EKS VPC CNI plugin for Kubernetes](https://docs.aws.amazon.com/eks/latest/userguide/managing-vpc-cni.html) user guide. 

## Running the stars example

### 1) Create the frontend, backend, client, and management-ui apps.

```shell
kubectl create -f manifests/
```

Wait for all the pods to enter `Running` state.

```shell
kubectl get pods --all-namespaces --watch
```

To connect to the management user interface, forward your local port 9001 to the management-ui service running on your cluster:

```shell
kubectl port-forward service/management-ui -n management-ui 9001
```

Open a browser on your local system and point it to http://localhost:9001/

Once all the pods are started, they should have full connectivity. You can see this by visiting the UI.  Each service is
represented by a single node in the graph.


### 2) Enable isolation

Running following commands will prevent all access to the frontend, backend, and client Services.

```shell
kubectl create -n stars -f policies/default-deny.yaml
kubectl create -n client -f policies/default-deny.yaml
```

#### Confirm isolation

Refresh the UI (it may take up to 10 seconds for changes to be reflected in the UI).
Now that we've enabled isolation, the UI can no longer access the pods, and so they will no longer show up in the UI.

### 3) Allow the UI to access the services using network policy objects

Apply the following YAMLs to allow access from the management UI.

```shell
kubectl create -f policies/allow-ui.yaml
kubectl create -f policies/allow-ui-client.yaml
```

After a few seconds, refresh the UI - it should now show the Services, but they should not be able to access each other any more.

### 4) Create the backend-policy.yaml file to allow traffic from the frontend to the backend

```shell
kubectl create -f policies/backend-policy.yaml
```

Refresh the UI. You should see the following:

- The frontend can now access the backend (on TCP port 6379 only).
- The backend cannot access the frontend at all.
- The client cannot access the frontend, nor can it access the backend.

### 5) Expose the frontend service to the client namespace

```shell
kubectl create -f policies/frontend-policy.yaml
```

The client can now access the frontend, but not the backend.  Neither the frontend nor the backend can initiate connections to the client.  The frontend can still access the backend.

To enforce egress policy on Kubernetes pods, see [the advanced policy demo](../advanced).

### 6) (Optional) Clean up the demo environment

You can clean up the demo by deleting the demo Namespaces:

```bash
./reset.sh
```
