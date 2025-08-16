# 🚀 Rocket.Chat One-Click Installer

**Automated deployment script for Rocket.Chat with production-ready configuration**

## ✨ Features
- **Complete Stack**: Rocket.Chat 7.9.3 + Node.js 22 + MongoDB 7.0
- **Security**: SSL (Let's Encrypt), MongoDB auth, dedicated system user
- **Infrastructure**: Nginx reverse proxy, systemd service, auto-renewing certificates

## 🛠️ Tech Stack
| Component       | Version  | Role                     |
|----------------|----------|--------------------------|
| Rocket.Chat    | 7.9.3    | Chat platform            |
| Node.js        | 22.x     | Runtime environment      |
| MongoDB        | 7.0.23   | Database                 |
| Nginx          | Latest   | Reverse proxy & SSL      |

## 🚀 Quick Start
```bash
# Download and execute (Ubuntu 20.04/22.04)
chmod +x rocket-install.sh && \
sudo ./rocket-install.sh

