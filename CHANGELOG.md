# Changelog

All notable changes to the Shopify MCP Server Cloudron package will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-20

### Added
- Initial release of Shopify MCP Server for Cloudron
- Basic MCP protocol support via supergateway
- Automatic health checks
- Environment variable configuration support
- Non-root user execution for security
- Persistent storage support via localstorage addon
- Docker Compose file for local testing
- Comprehensive documentation

### Technical Details
- Based on Node.js 18 Alpine
- Uses @shopify/dev-mcp latest version
- Uses @latitude-data/supergateway for protocol handling
- Cloudron base image 4.2.0
- Memory limit set to 512MB by default

### Known Issues
- MCP server requires manual API credential configuration
- No built-in authentication (relies on Cloudron's reverse proxy)

## [Unreleased]

### Planned Features
- [ ] Web-based configuration UI
- [ ] Automatic Shopify webhook registration
- [ ] Built-in request logging and analytics
- [ ] Support for multiple Shopify stores
- [ ] Backup and restore functionality
- [ ] Rate limiting configuration
- [ ] Custom middleware support