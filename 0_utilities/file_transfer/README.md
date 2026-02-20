# WordPress Export Scripts - Xneelo to AWS Migration

A collection of bash scripts for exporting WordPress websites from Xneelo hosting servers to local directories, designed to automate the complete migration process from Xneelo to AWS or other hosting platforms.

## Available Scripts

### 🌟 **wordpress-xneelo-export.sh** (Recommended)

**The comprehensive, all-in-one export solution.**

This is the most complete and feature-rich script with:
- Automated WordPress root detection (public_html, httpdocs, etc.)
- Server-side database export with automatic credential extraction
- Dual export method: tar.gz archive + rsync synchronization
- Intelligent file exclusions (cache, logs)
- SHA256 checksum generation for integrity verification
- Detailed export documentation with environment info
- Automated local downloads via SCP
- Optional server cleanup
- Color-coded progress reporting
- Comprehensive error handling

**Use this script for:** Complete WordPress migrations from Xneelo to AWS

### export-wordpress.sh (Original)

The original export script with basic functionality. Superseded by `wordpress-xneelo-export.sh`.

### server-export.sh

Server-side operations script for manual use when already SSH'd into the server.

### download-exports.sh

Standalone download script for fetching previously created export files.

## Features

- **Automated SSH Connection**: Connects to Xneelo servers using custom port (2222)
- **Database Export**: Automatically extracts credentials from wp-config.php and exports MySQL database
- **File Archiving**: Creates compressed tar.gz archives of WordPress files
- **Rsync Synchronization**: Syncs files with intelligent exclusions (cache, logs)
- **Checksum Verification**: Generates SHA256 checksums for data integrity
- **Documentation**: Creates detailed export notes with environment information
- **Local Download**: Automatically downloads all exports via SCP
- **Optional Cleanup**: Can clean up temporary files on server after export
- **Error Handling**: Comprehensive error checking and validation at each step
- **Progress Reporting**: Color-coded output with detailed progress information

## Prerequisites

### Required Tools
- `bash` (version 4.0 or higher)
- `ssh` client with key-based authentication configured
- `scp` for secure file transfer
- `rsync` for file synchronization
- `mysqldump` (on the remote server)
- `tar` (on the remote server)

### Required Access
- SSH access to Xneelo server
- Xneelo server credentials (username, hostname)
- Sufficient disk space locally for exports
- Network connectivity to Xneelo servers

### SSH Key Setup (Recommended)

To avoid password prompts during export, set up SSH key authentication:

```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key to Xneelo server
ssh-copy-id -p 2222 username@servername.xneelo.co.za

# Test connection
ssh -p 2222 username@servername.xneelo.co.za
```

## Quick Start

**New to this script?** See **[QUICK_START.md](QUICK_START.md)** for a 5-minute setup guide.

**Need detailed instructions?** See **[SETUP_GUIDE.md](SETUP_GUIDE.md)** for complete setup and troubleshooting.

## Installation

1. **Clone or download the scripts**:
   ```bash
   git clone <repository-url>
   cd file_transfer
   ```

2. **Make the recommended script executable**:
   ```bash
   chmod +x wordpress-xneelo-export.sh
   ```

3. **Verify script is ready**:
   ```bash
   ./wordpress-xneelo-export.sh --help
   ```

**For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)**

## Usage (wordpress-xneelo-export.sh)

### Basic Syntax

```bash
./wordpress-xneelo-export.sh -w <website-name> -u <ssh-username> [OPTIONS]
```

### Required Parameters

- `-w, --website-name NAME`: Website name (creates matching local directory)
- `-u, --ssh-user USER`: SSH username for Xneelo server

### Optional Parameters

- `-h, --ssh-host HOST`: SSH hostname/IP (default: 197.221.10.19)
- `-p, --ssh-port PORT`: SSH port (default: 2222)
- `-r, --wp-root PATH`: WordPress root path (default: auto-detect)
- `--skip-cleanup`: Don't cleanup export files on server after download
- `--rsync-only`: Use rsync only, skip tar archive creation
- `--help`: Display help message

**Note**: WordPress root auto-detection tries these paths in order:
- public_html
- httpdocs
- www
- public_html/httpdocs

### Examples

#### Basic Export
Export WordPress website with default settings (auto-detects WordPress root):

```bash
./wordpress-xneelo-export.sh -w mywebsite -u aupaiqzaea
```

#### Export with Custom Xneelo Server
Export from a specific Xneelo server:

```bash
./wordpress-xneelo-export.sh -w clientwebsite -u username -h 197.221.12.211
```

#### Export Without Server Cleanup
Keep temporary files on server after export (useful for debugging):

```bash
./wordpress-xneelo-export.sh -w mywebsite -u aupaiqzaea --skip-cleanup
```

#### Export Using Rsync Only
Skip tar archive creation, use rsync only for faster sync:

```bash
./wordpress-xneelo-export.sh -w mywebsite -u aupaiqzaea --rsync-only
```

#### Custom WordPress Root
If WordPress is in a non-standard location (overrides auto-detection):

```bash
./wordpress-xneelo-export.sh -w mywebsite -u aupaiqzaea -r public_html/subdomain
```

## What the Script Does

### Step-by-Step Process

1. **Verify Connection**: Tests SSH connection and verifies WordPress installation
2. **Extract Credentials**: Reads database credentials from wp-config.php
3. **Export Database**: Uses mysqldump to export complete MySQL database
4. **Archive Files**: Creates tar.gz archive of WordPress files (optional)
5. **Generate Checksums**: Creates SHA256 checksums for verification
6. **Create Documentation**: Generates detailed export notes
7. **Rsync Files**: Syncs WordPress files with intelligent exclusions
8. **Download Exports**: Downloads all export files to local directory
9. **Verify Downloads**: Confirms all files downloaded successfully
10. **Cleanup Server**: Removes temporary files from server (optional)

### File Exclusions

The script automatically excludes these directories from sync:
- `wp-content/cache/*`
- `wp-content/uploads/cache/*`
- `*.log` files

### Export Directory Structure

```
exports/
└── website-name/
    ├── wordpress-db-TIMESTAMP.sql          # Database export
    ├── wordpress-files-TIMESTAMP.tar.gz    # File archive (if not rsync-only)
    ├── CHECKSUMS-TIMESTAMP.txt             # SHA256 checksums
    ├── EXPORT-NOTES-TIMESTAMP.txt          # Export documentation
    └── public_html/                        # Rsync'd WordPress files
        ├── wp-admin/
        ├── wp-content/
        ├── wp-includes/
        ├── wp-config.php
        └── ...
```

## Output and Logging

### Console Output

The script provides color-coded output:
- **Blue**: Section headers and informational messages
- **Green**: Success messages (✓)
- **Yellow**: Warnings (⚠)
- **Red**: Errors (✗)

### Export Notes

The script generates an `EXPORT-NOTES-TIMESTAMP.txt` file containing:
- Export date and timestamp
- Website and server information
- Database credentials
- PHP version and WordPress path
- List of installed plugins and themes
- Export process summary
- Next steps for migration

## Troubleshooting

### SSH Connection Issues

**Problem**: Connection timeout or refused

```bash
# Test SSH connection manually
ssh -p 2222 username@servername.xneelo.co.za

# Check if custom port is accessible
telnet servername.xneelo.co.za 2222
```

**Solution**:
- Verify SSH credentials
- Check firewall rules
- Confirm SSH key is added to server

### Database Export Fails

**Problem**: mysqldump fails or produces empty file

```bash
# SSH into server and test mysqldump manually
ssh -p 2222 username@servername.xneelo.co.za
cd public_html
mysqldump -u DB_USER -p DB_NAME > test.sql
```

**Solution**:
- Verify database credentials in wp-config.php
- Check MySQL user permissions
- Ensure sufficient disk space on server

### Rsync Permission Errors

**Problem**: Rsync fails with permission denied

**Solution**:
- Check file ownership on server
- Verify SSH user has read access to WordPress files
- Try running with `--rsync-only` flag

### Large File Transfers

**Problem**: Transfers timeout or fail for large websites

**Solution**:
- Use `--rsync-only` to avoid creating large tar archives
- Increase SSH timeout settings
- Run script during off-peak hours
- Consider splitting export into multiple runs

### Checksum Verification Fails

**Problem**: Downloaded files don't match checksums

**Solution**:
- Re-download the specific file
- Check network connection stability
- Verify disk space on local machine

## Security Considerations

### Credentials

- **Never commit SSH credentials** to version control
- Use SSH key authentication instead of passwords
- Store database passwords securely
- Delete export files from server after download (`--skip-cleanup` disabled)

### Database Export

- Database export contains **sensitive information**:
  - User passwords (WordPress hashes)
  - Email addresses
  - Site configuration
- **Secure the export directory** with appropriate permissions:
  ```bash
  chmod 700 exports/
  chmod 600 exports/website-name/*.sql
  ```

### Server Cleanup

- Always cleanup temporary files unless debugging:
  ```bash
  ./export-wordpress.sh -w website -u user  # Cleans up by default
  ```

## Migration Workflow

### Complete Migration Process

1. **Export from Xneelo**:
   ```bash
   ./export-wordpress.sh -w mywebsite -u aupaiqzaea
   ```

2. **Prepare AWS Environment**:
   - Launch EC2 instance or use AWS Lightsail
   - Install WordPress stack (Apache/Nginx, MySQL, PHP)
   - Configure domain and SSL certificate

3. **Import Database**:
   ```bash
   mysql -u new_db_user -p new_db_name < exports/mywebsite/wordpress-db-*.sql
   ```

4. **Update Site URL** (if domain changed):
   ```sql
   USE new_db_name;
   UPDATE wp_options SET option_value='https://newdomain.com' WHERE option_name='siteurl';
   UPDATE wp_options SET option_value='https://newdomain.com' WHERE option_name='home';
   ```

5. **Upload Files**:
   ```bash
   rsync -avz exports/mywebsite/public_html/ user@aws-server:/var/www/html/
   ```

6. **Update wp-config.php**:
   - Update database credentials
   - Update database host
   - Update authentication keys/salts

7. **Set Permissions**:
   ```bash
   chown -R www-data:www-data /var/www/html/
   find /var/www/html/ -type d -exec chmod 755 {} \;
   find /var/www/html/ -type f -exec chmod 644 {} \;
   ```

8. **Test Website**:
   - Verify homepage loads
   - Test admin login
   - Check all pages and posts
   - Verify forms and plugins
   - Test email functionality

9. **Update DNS**:
   - Point domain to new AWS server
   - Wait for DNS propagation (24-48 hours)

## Advanced Usage

### Automating Multiple Sites

Create a batch export script:

```bash
#!/bin/bash

sites=(
    "website1:user1"
    "website2:user2"
    "website3:user3"
)

for site in "${sites[@]}"; do
    IFS=':' read -r name user <<< "$site"
    ./export-wordpress.sh -w "$name" -u "$user"
done
```

### Custom Exclusions

Modify the rsync command in the script to add custom exclusions:

```bash
rsync -avz --progress \
    --exclude='wp-content/cache' \
    --exclude='wp-content/uploads/cache' \
    --exclude='wp-content/uploads/backup' \
    --exclude='custom-folder' \
    -e "ssh -p ${SSH_PORT}" \
    "${SSH_CONNECTION}:~/${REMOTE_WP_ROOT}/" \
    "${EXPORT_DIR}/public_html/"
```

### Scheduling Exports

Use cron to schedule regular exports:

```bash
# Edit crontab
crontab -e

# Add entry for weekly Sunday 2 AM exports
0 2 * * 0 /path/to/export-wordpress.sh -w mywebsite -u username
```

## Script Configuration

### Default Values

You can modify default values at the top of the script:

```bash
DEFAULT_SSH_PORT=2222          # Default SSH port
DEFAULT_SSH_HOST="197.221.10.19"  # Default Xneelo IP
DEFAULT_WP_ROOT="public_html"  # Default WordPress root
```

### Timestamp Format

Exports are timestamped using format: `YYYYMMDD_HHMMSS`

Example: `wordpress-db-20260112_143000.sql`

## Support and Contribution

### Reporting Issues

If you encounter issues:

1. Run script with verbose output
2. Check export notes file for details
3. Review server logs if accessible
4. Document error messages and steps to reproduce

### Contributing

Contributions are welcome! Consider adding:
- Support for additional hosting providers
- Enhanced error recovery
- Parallel file transfers
- Incremental backup support
- WordPress plugin/theme updates during export

## License

This script is provided as-is for WordPress migration purposes.

## Changelog

### Version 2.0.0 (2026-01-12) - wordpress-xneelo-export.sh
- **NEW**: Comprehensive all-in-one export script (recommended)
- **NEW**: Automated WordPress root detection (public_html, httpdocs, www, public_html/httpdocs)
- **NEW**: Enhanced error handling with detailed error messages
- **NEW**: Improved progress reporting with color-coded sections
- **NEW**: Dual export method: tar.gz + rsync for maximum flexibility
- **NEW**: Environment information collection (PHP version, plugins, themes)
- **NEW**: Comprehensive export documentation generation
- **NEW**: Automatic download verification
- **IMPROVED**: Better SSH connection testing
- **IMPROVED**: More robust database credential extraction
- **IMPROVED**: Enhanced checksum verification workflow
- Server-side operations via SSH
- Database export with mysqldump
- File archiving with tar.gz
- Rsync synchronization with intelligent exclusions
- SHA256 checksum generation
- Automated downloads via SCP
- Optional server cleanup
- Color-coded progress output

### Version 1.0.0 (2026-01-12) - export-wordpress.sh
- Initial release
- SSH connection to Xneelo servers
- Database export with mysqldump
- File archiving with tar.gz
- Rsync synchronization with exclusions
- Checksum generation
- Export documentation
- Automated downloads via SCP
- Optional server cleanup
- Color-coded progress output

## Credits

- Designed for WordPress migration from Xneelo to AWS
- Based on Xneelo hosting platform structure
- Optimized for Plesk/cPanel WordPress installations

## Additional Resources

- [WordPress Codex: Moving WordPress](https://wordpress.org/support/article/moving-wordpress/)
- [Xneelo Support Documentation](https://xneelo.co.za/help-centre/)
- [AWS WordPress Hosting](https://aws.amazon.com/wordpress/)
- [WordPress Migration Best Practices](https://wordpress.org/support/article/moving-wordpress/)
