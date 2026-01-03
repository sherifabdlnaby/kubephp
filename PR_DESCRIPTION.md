# KubePHP 2.0.0 - Major Upgrade & Feature Release

## 🚀 Overview

This release brings significant upgrades, performance optimizations, and new features to KubePHP, including multi-architecture support, PHP 8.4 optimizations, and enhanced developer experience.

## ⚠️ Breaking Changes

- **PHP**: Upgraded from 8.1 to **8.4**
- **Alpine**: Upgraded from 3.16 to **3.21**
- **Nginx**: Upgraded from 1.21 to **1.28**
- **Xdebug**: Upgraded from 3.1.3 to **3.5.0**
- **Docker Compose**: Migrated to V2 syntax (removed deprecated `version` field)

## ✨ New Features

### Multi-Architecture Support
- Native support for **AMD64** and **ARM64** platforms
- CI/CD workflows updated to build and test both architectures
- Enables deployment on modern cloud platforms including Apple Silicon and ARM-based servers

### PHP 8.4 Performance Optimizations
- **JIT compilation** enabled by default (tracing mode, 100M buffer)
- **OPcache file cache** for faster PHP process restarts
- Enhanced OPcache configuration with improved memory management
- Production-ready PHP settings with security hardening

### Laravel Demo Application
- Full Laravel demo support alongside existing Symfony demo
- Automated setup with `make demo/laravel/setup`
- Production optimizations (config, routes, views, events caching)
- Unified command structure: `demo/symfony/*` and `demo/laravel/*`

### Enhanced Developer Experience
- Improved Xdebug 3.5.0 configuration with PHPStorm-ready defaults
- Better documentation with collapsible sections and inline links
- Streamlined Makefile commands

## 🔧 Improvements

- **PHP Configuration**: Refined base, dev, and production PHP settings with better defaults
- **Nginx Configuration**: Improved asset handling and IPv6 support for monitoring endpoint
- **CI/CD**: Enhanced GitHub Actions workflows with multi-arch builds, improved caching, and better test coverage
- **Documentation**: Comprehensive updates including XDebug setup guide and demo application instructions
- **Build Process**: Added PECL extension verification to catch silent installation failures

## 🗑️ Removed & Simplified

### Docker Compose Migration
- **Removed** `version: '3.7'` field from docker-compose files (migrated to V2 syntax)
- **Simplified** all `docker-compose` commands to `docker compose` (V2 CLI)

### Makefile Simplification
- **Removed** `COMPOSE_PREFIX_CMD` variable wrapper
- **Simplified** all commands to use direct `docker compose` calls
- BuildKit and Compose CLI build flags are now handled automatically by Docker Compose V2

### Workflow Cleanup
- **Removed** verbose boilerplate comments from GitHub Actions workflows
- **Simplified** workflow structure with clearer job names and organization

### Configuration Cleanup
- **Simplified** Xdebug configuration comments (standardized to INI-style comments)
- **Cleaned up** PHP configuration file comments for better readability

## 📦 Technical Details

- Image size remains minimal (~135 MB)
- All security best practices maintained (non-root execution, minimal attack surface)
- Backward compatible with existing applications (PHP 8.2+)

---

**Migration Note**: Applications using PHP 8.1 or earlier will need to upgrade to PHP 8.2+ to use this release. Docker Compose V2 is required (included with Docker Desktop 4.0+).
