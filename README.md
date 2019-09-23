<p align="center">
  <img width="450px" src="https://user-images.githubusercontent.com/16992394/65399515-5a985180-ddbd-11e9-8f3b-3bb9bc7858f7.png">
</p>
<h2 align="center">🐳 An extendable multistage PHP Symfony 4.3+ Docker Image for Production and Development</h2>

## Introduction
Docker Image for Symfony 4.3+ Application running on Apache 2.4 based on PHP Official Image.
This image shall be used as a **base** image for your Symfony Project, and you shall extend and edit it according to your needs.
The Image utilizes docker's multistage builds to create multiple targets optimized for **production** and **development**.


You should copy this repository `Dockerfile`, `.docker` and `.dockerigonre` to your Symfony application repository and configure it to your needs.

### Main Points 📜

- Production Image is a fully contained Image that copies source code and dependencies inside _efficiently_, while Development image is set up for mounting source code on runtime to allow development using the container.
- Image configuration is transparent, you can view and modify any of Apache's `*.conf`, PHP `*.ini` config or Entrypoint `*.sh` scripts present in the `.docker` directory. 
- PHP version is upgradable using build time ARGs (default **PHP 7.3.9**)
- By Default, **Apache SSL is enabled**, and hence run **HTTP** and **HTTPS** endpoints, with **HTTPS** it uses self-signed certificate generated at runtime. however, for production you'll need to mount your own signed certificates to `/etc/apache2/certs` amd overwrite defaults.
- Image tries to fail at build time as much as possible by running all sort of Checks.
- Production Image is only 3MBs bigger than PHP with Apache official image. (excluding vendor and source code).
