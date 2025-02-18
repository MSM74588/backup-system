# Only Jellyfin.

- Follow [Steps.md](../STEPS.md)

```bash
# Create directories
mkdir -p jellyconfig jellycache

# Set proper permissions
sudo chown -R $USER:shared_access jellyconfig jellycache
sudo chmod -R 775 jellyconfig jellycache
```