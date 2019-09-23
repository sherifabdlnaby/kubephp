<p align="center">
  <img width="450px" src="https://user-images.githubusercontent.com/16992394/65399515-5a985180-ddbd-11e9-8f3b-3bb9bc7858f7.png">
</p>
<h2 align="center">🐳 An extendable multistage PHP Symfony 4.3+ Docker Image for Production and Development</h2>

# Introduction
Docker Image for Symfony 4.3+ Application running on Apache 2.4 based on [PHP Official Image](https://hub.docker.com/_/php).
This image shall be used as a **base** image for your Symfony Project, and you shall extend and edit it according to your needs.
The Image utilizes docker's multistage builds to create multiple targets optimized for **production** and **development**.


You should copy this repository`Dockerfile`, `.docker` Directory, `Makefile`, and `.dockerignore` to your Symfony application repository and configure it to your needs.

## Main Points 📜

- Production Image is a fully contained Image that copies source code and dependencies inside _efficiently_ **only 3MBs bigger than base image**, Development image is set up for mounting source code on runtime to allow development using the container.

- Image configuration is transparent, you can view and modify any of Apache's `*.conf` files, PHP `*.ini` files or Entrypoint `*.sh` scripts in the `.docker` directory. 

- **Apache SSL is enabled**, and hence run **HTTP** and **HTTPS** endpoints, with **HTTPS** it uses self-signed certificate generated at runtime. however, for production you'll need to mount your own signed certificates to `/etc/apache2/certs` amd overwrite defaults.

- Image tries to fail at build time as much as possible by running all sort of Checks.

- Dockerfile is arranged for optimize builds, so that changed won't invalidate cache as much as possible.

- As Symfony 4+ [Uses Environment Variables](https://symfony.com/doc/4.3/configuration.html#configuration-based-on-environment-variables) for parameters, and only passing environment variables to the container is enough to be read by symfony. (no need to pass them through Apache2 conf too).

# Requirements 

- [Docker 17.05 or higher](https://docs.docker.com/install/) 
- [Docker-Compose 3.4 or higher](https://docs.docker.com/compose/install/) (optional) 
- Symfony 4+ Application

# Setup

1. Clone The Repository
2. Copy `Dockerfile`, `.docker` Directory, `Makefile`, and `.dockerignore` Into your Symfony Application Repository.
3. Modify `Dockerfile` to your app needs, and add your app needed PHP Extensions and Required Packages.
4. Situational:
    - If you will use `Makefile` and `Docker-Compose`: go to `.docker/.composer/.env` and modify `SERVER_NAME` to your app's name.
    - If you will expose SSL port to Production: Mount your signed certificates `server.crt` & `server.key` to `/etc/apache2/certs`.
      Also make sure `SERVER_NAME` build ARG matches Certificate's **Common Name**.
5. run `make up` for development or `make deploy` for production. 
      
## Building Image

1. The image is to be used as a base for your Symfony application image, you should modify its Dockerfile to your needs.

2. The image come with a handy _Makefile_ to build the image using Docker-Compose files, it's handy when manually building the image for development or in a not-orchestrated docker hosts.
However in an environment where CI/CD pipelines will build the image, they will need to supply some build-time arguments for the image. (tho defaults exist.)

### Build Time Arguments
| **ARG**            | **Description**                                                                                                                                      | **Default** |
|--------------------|------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| `PHP_VERSION`      | PHP Version used in the Image                                                                                                                        | `7.3.9`     |
| `COMPOSER_VERSION` | Composer Version used in Image                                                                                                                       | `1.9.0`     |
| `SERVER_NAME`      | Server Name (In production, and using SSL, this must match certificate's *common name*)                                                              | `php-app`   |
| `COMPOSER_AUTH`    | A Json Object with Bitbucket or Github token to clone private Repos with composer.  [Reference](https://getcomposer.org/doc/03-cli.md#composer-auth) | `{}`        | 

### Runtime Environment Variables
| **ENV**     | **Description** | **Default**                                                 |
|-------------|-----------------|-------------------------------------------------------------|
| `APP_ENV`   | App Environment | - `prod` for Production image                               |
|             |                 | - `dev` for Development image                               |
| `APP_DEBUG` | Enable Debug    | - `0` for Production image                                  |
|             |                 | - `1` for Development image                                 |

### Tips for building Image in different environments

#### Production
1. For SSL: Mount your signed certificates as secrets to `/etc/apache2/certs/server.key` & `/etc/apache2/certs/server.crt`
2. Make sure build argument `SERVER_NAME` matches certificate's **common name**.
2. Expose container port `80` and `443`.

> You can disable SSL by modifying `site.conf` in `.docker/conf/apache2` config if you don't need HTTPS or is having it using a front loadbalancer/proxy.

> By default, Image has a generated self-signed certificate for SSL connections added at run time.
#### Development
1. Mount source code root to `/var/www/app`
2. Expose container port `8080` and `443`. (or whatever you need actually)

### License 
MIT License
Copyright (c) 2019 Sherif Abdel-Naby

### Contribution

PR(s) are Open and welcomed.

This image has so little to do with Symfony itself and more with Setting up a PHP Website with Apache, hence it can be extended for other PHP Frameworks (e.g Laravel, etc). maybe if you're interested to build a similar image for another framework we can collaborate. 

