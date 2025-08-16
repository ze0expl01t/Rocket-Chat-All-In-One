**Rocket.Chat Auto-Installation Script**</br>

**📌 Overview**</br>
This bash script automates the installation of a complete Rocket.Chat server with all necessary dependencies on Ubuntu 20.04/22.04 LTS. It configures:</br>
Rocket.Chat 7.9.3</br>
Node.js v22</br>
MongoDB 7.0.23</br>
Mongosh 2.5.6</br>
Nginx reverse proxy</br>
Let's Encrypt SSL certificates</br>
Secure MongoDB configuration</br>

**🛠️ Features**</br>
Complete stack installation in one command</br>
**Secure MongoDB configuration with:**</br>
Replica set initialization,</br>
Dedicated admin user,</br>
Rocket.Chat database user,</br>
Authentication enforcement</br>
**Production-ready setup with:**</br>
Systemd service,</br>
Nginx reverse proxy,</br>
Automatic SSL (Let's Encrypt),</br>
Certificate auto-renewal,</br>
Detailed output with color-coded status messages,</br>
Admin user auto-creation for Rocket.Chat.</br>

**⚙️ Technical Specifications**</br>
Component	Version	Configuration Details,</br>
Rocket.Chat	7.9.3	Systemd service, runs as dedicated user,</br>
Node.js	22.x	With npm and build tools,</br>
MongoDB	7.0.23	With replica set, authentication,</br>
Mongosh	2.5.6	MongoDB shell client,</br>
Nginx	Latest	Reverse proxy with SSL termination,</br>
Certbot	Latest	Automatic SSL certificates.</br>

🔐 Security Features</br>
MongoDB authentication enabled,</br>
Separate users for admin and application,</br>
Restricted database permissions,</br>
SSL encryption by default,</br>
Runs Rocket.Chat as non-root user.</br>
utomatic security updates for certificates
