<p align="center">
  <br><br>
  <img width="450px" src="https://user-images.githubusercontent.com/16992394/65399515-5a985180-ddbd-11e9-8f3b-3bb9bc7858f7.png">
</p>
<h2 align="center">🐳 An extendable multistage PHP Symfony 4.3+ Docker Image for Production and Development</h2>

## Introduction
Docker Image for Symfony 4.3+ Application running on Apache 2.4 based on PHP Official Image.
This image shall be used as a **base** image for your Symfony Project, and you shall extend and edit it according to your needs.
The Image utilizes docker's multistage builds to create multiple targets optimized for **production** and **development**.


You should copy this repository `Dockerfile`, `.docker` and `.dockerigonre` to your Symfony application repository and configure it to your needs.

### In Points 📜

- Production Image is a fully contained Image that copies source code and dependencies inside _efficiently_, while Development image is set up for mounting source code on runtime to allow development using the container.

- PHP version is upgradable using build time ARGs (default **PHP 7.3.9** ), as well as Composer version (default: **Composer 1.9.0**).

- Installing Dependencies via Composer is **done in a separate image during build to reduce final image size.** (this is for production, in dev, code is mounted anyway.)

- Dockerfile is arranged for optimize builds, so that changed won't invalidate cache as much as possible.

- Image configuration is transparent, you can view and modify any of Apache **.conf**, PHP **.ini** config or **Entrypoint** scripts present in the `.docker` directory. 

- By Default, **Apache SSL is enabled**, and hence run **HTTP** and **HTTPS** endpoints, with **HTTPS** it uses self-signed certificate generated at runtime. however, for production you'll need to mount your own signed certificates to `/etc/apache2/certs` amd overwrite defaults.

- As Symfony 4+ Uses Environment Variables for parameters, and only passing environment variables to the container is enough to be read by symfony. (no need to pass them through Apache2 conf too).

- For production, uses recommended optimization such as optimize autoload and dump `.env` files to `.env.local.php`.

- For cloning private repos during build time, use `COMPOSER_AUTH` build ARG. [Docs](https://getcomposer.org/doc/03-cli.md#composer-auth)

- Composer _post-install_ scripts are run on Container runtime during startup, as it often need to connect to network/databases/services/etc.

- Sometimes Composer post-install scripts are not sufficient(very situational), a `post-deployment.sh` script is added to the image that will run before starting apache, this shall be used for ad-hoc commands, and commands that's hard to be automated via Composer scripts.
  modify this `post-deployment.sh` for your ad-hoc needs. This scripts will have all environment variables loaded (from OS, .env and .env.<APP_ENV>) accessed via POSIX expression `${PARAMETER_NAME}` 

- Image will not output any logs except Apache logs, Application logs (if configured to print to _stdout_) and if errors occurred during initial post deployment scripts. This makes it easy to ship and parse container logs to centralized logging systems (e.g Elastic Stack)


- Image tries to fail at build time as much as possible by running all sort of Checks.

- Production Image is only 3MBs bigger than PHP with Apache official image. (excluding vendor and source code).

- Comes with a _makefile_ and a _docker-compose.yml_ to ease development and deployments on not orchestrated docker hosts.
