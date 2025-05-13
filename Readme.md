# Trembita Secure Data Exchange Gateway 1.12.6 – Docker + Helm

This repository contains Helm charts and a Dockerfile for deploying the **Secure Data Exchange Gateway (SDX)** of the **Trembita** system, version **1.12.6**, in a **Kubernetes** environment. The solution has been tested with **ArgoCD** and is designed for a single-node (non-scalable) deployment, with the potential to be adapted for scalability.

---

## 📦 Repository Structure

| Path                                 | Description                             |
|--------------------------------------|------------------------------------------|
| `argo_cd_helm/trembita-1.12.6-ss/`   | Helm chart for deploying the gateway     |
| `Dockerfile`                         | Dockerfile for building the container    |
| `values.yaml`                        | Example Helm configuration               |
| `README.md`                          | This documentation file                  |

---

## 🚀 Quick Start

### 1. Build Docker Image

The `Dockerfile` is located at the **root** of the project. To build the image:

```bash
docker build -t .
```

> ⚠️ **Note:** By default, the Helm chart references a **private Docker Hub image**. It is strongly recommended to build your own image and push it to a private registry (e.g., Harbor, GHCR, ECR, etc.).

---

### 2. Install via Helm

```bash
helm upgrade --install trembita ./argo_cd_helm/trembita-1.12.6-ss -f values.yaml
```
> Ensure your Kubernetes cluster supports `PersistentVolume` and `Ingress`.

---

## 👤 Web Interface Access

By default, the following user is created:

- **Username:** `uxpadmin`
- **Password:** `uxpadminp`

You can override the password by setting the environment variable `UXPADMIN_PASS`:

```yaml
env:
  - name: UXPADMIN_PASS
    value: "your_secure_password"
```

---

## 📁 Volume Structure

The application uses four mounted volumes:

| Container Path                  | Purpose                                  |
|---------------------------------|-------------------------------------------|
| `/etc/uxp`                      | Gateway configuration                     |
| `/var/lib/uxp`                  | Runtime data                              |
| `/var/lib/postgresql/10/main`  | PostgreSQL data                           |
| `/var/log`                      | System and application logs               |

> These directories are initialized using `initContainers` defined in the Helm chart.

---

## 🌐 Networking

### The application uses the following ports:

| Purpose                             | Container Port | External Access                    |
|-------------------------------------|----------------|-------------------------------------|
| Web UI                              | 4000 (HTTP)    | Exposed via Ingress (HTTPS-terminated) |
| Internal Services                      | 5500           | Exposed via LoadBalancer           |
| Internal Services                       | 5577           | Exposed via LoadBalancer           |
| Internal Services                   | 5599           | Exposed via LoadBalancer           |
| HTTP endpoint for external access   | 80             | Ingress (use a dedicated subdomain) |
| HTTPS (443)                         | ❌ Not used    | —                                   |

> **Ingress Controller** handles HTTPS termination. All traffic is forwarded to port **80 (HTTP)** inside the container. It is recommended to assign a **dedicated domain name** for public access to port 80 (e.g., `gateway.example.org`).

---

## ⚠️ Scalability

This setup is **not scalable out-of-the-box** due to:

- Local PostgreSQL instance
- Non-shared `/etc/uxp` directory
- Manual token login handling

### Recommendations for scaling:

- Move PostgreSQL to a dedicated service or cluster
- Use a shared volume or distributed storage for `/etc/uxp`
- Implement automatic login/authentication for tokens

---

## ✅ Compatibility

| Component        | Version/Notes           |
|------------------|--------------------------|
| Kubernetes       | **1.33+**                |
| ArgoCD           | Verified                 |
| Docker           | Based on `ubuntu:18.04`  |

---

## 📄 License

MIT or other licenses as applicable to Trembita components.

---

## 🤝 Author

- **GitHub:** [@kshypachov](https://github.com/kshypachov)

---

If you need help generating a `values.yaml.example`, preparing an Ingress manifest, or adding CI/CD for automatic image builds and deployment — feel free to ask!