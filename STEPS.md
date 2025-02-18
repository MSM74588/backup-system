# Steps to create a robust share from the start

    note:
    - here, user: mediauser; group: shared_access

---

    # On both NixOS and OMV, create a shared user with the same UID/GID
    # For example, on NixOS (add to configuration.nix):
        users.users.mediauser = {
        isNormalUser = true;
        uid = 1500;  # Choose a consistent UID
        group = "mediagroup";
        };

        users.groups.mediagroup = {
        gid = 1500;  # Choose a consistent GID
        };

    # then, setpassword -> sudo passwd mediauser

    # On OMV, create the same user
        sudo useradd -u 1500 -g 1500 -m mediauser
        sudo groupadd -g 1500 mediagroup

    # then, setpassword -> sudo passwd mediauser (not necessary?)

---

    ON OMV WebUI
        - Create Shared Folder
            For your media folder:
                Set owner to: mediauser
                Set group to: shared_access
                Set permissions: 775
                Enable "Set group sticky bit" (this ensures new files inherit the group)

        - Then via [Permissions] adjust read/write (generally not needed)
        - Then via [Access Control List] change Owner to "mediauser", group to "shared_access", and permission to "Read/Write/Exexute" for Owner, Group and Others i.e 777

        - Then enable NFS and SMB
        - For NFS:
            Add a new share with these settings:
                Shared folder: Your media folder
                Client: Your NixOS IP/subnet (e.g., 192.168.0.0/24)
                Privileges: rw (read-write)
                Extra options: rw,sync,no_subtree_check,all_squash,anonuid=<media_user_uid>,anongid=<mediagroup_gid>
                Edited: rw,sync,no_subtree_check,all_squash,anonuid=1500,anongid=1500
        - NixOS:
              # Mount the NFS share
                fileSystems."/mnt/media" = {
                    device = "omv_ip:/srv/nfs/media";  # Replace omv_ip with your OMV IP
                    fsType = "nfs";
                    options = [ "rw" "soft" "nfsvers=4.2" "x-systemd.automount" "noauto" ];
                };

---
    Setup Samba share to access:


        First, Add User Permissions:

            Go to Access Rights Management → User
            Confirm your user 'msm' exists
            Go to Access Rights Management → Group
            Make sure 'msm' is a member of shared_access group

        Set Shared Folder Permissions:

            Go to Storage → Shared Folders
            Find your media share
            Click on Privileges
            For user 'msm':
                Set to Read/Write permissions
            For group shared_access:
                Set to Read/Write permissions
            Click Save

        Configure Samba Share Permissions:

            Go to Services → SMB/CIFS
            Edit your media share
            Under Permissions:
                Make sure 'msm' is listed with Read/Write access
                Make sure shared_access group has Read/Write access

---
    Configure Samba SMB share:
        1. Go to Services → SMB/CIFS
        2. Edit your share: (share specific)

            - Enable "Inherit permissions"
            - Enable "Inherit owner"
            - Under "Extra Options/Additional Options field" set:

                inherit permissions = yes
                inherit owner = yes
                create mask = 0664
                directory mask = 0775

        

            Set Permissions:
            
                Go back to Storage → Shared Folders
                Select your media share
                Click Privileges
                Set:
                    User MSM74588: Read/Write
                    User mediauser: Read/Write
                    Group "shared_access": Read/Write
            

---

## Jellyfin Testing

    Setting up docker:
    
        self Note: I have "msm" user that is running/controlling docker, the default user that was created at start with nix

docker-compose.yml

```yml
services:
  backupsystem-jellyfin-camera:
    env_file: 
      - ./.env
    image: jellyfin/jellyfin
    container_name: backupsystem-jellyfin-camera
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ./jellyconfig:/config
      - ./jellycache:/cache
      - type: bind
        source: ${CAMERA_PATH}
        target: /media/camera
        bind:
          create_host_path: true
    restart: unless-stopped
    ports:
      - ${JELLYFIN_PORT}:8096
      #- ${JELLYFIN_HTTPS_PORT}:8920
      #- ${JELLYFIN_DISCOVERY_PORT}:7359/udp
      #- ${JELLYFIN_DLNA_PORT}:1900/udp
```
.env
```sh
# User and Group IDs
PUID=1010
PGID=1000

# Timezone
TZ=Asia/Kolkata

# Media Paths
BACKUP_MEDIA_BASE=/mnt/backup_media_system/backup_media_pool
CAMERA_PATH=${BACKUP_MEDIA_BASE}/camera

# Jellyfin Ports
JELLYFIN_PORT=8090
#JELLYFIN_HTTPS_PORT=8920
#JELLYFIN_DISCOVERY_PORT=7359
#JELLYFIN_DLNA_PORT=1900
```
```bash
# Create directories
mkdir -p jellyconfig jellycache

# Set proper permissions
sudo chown -R $USER:shared_access jellyconfig jellycache
sudo chmod -R 775 jellyconfig jellycache
```
```bash
# Check permissions on media directory
ls -l /mnt/backup_media_system/backup_media_pool/camera
```
```bash
# Start container
sudo docker compose up -d
```

> [!IMPORTANT]
> Add the paths manually in Libraries section

---

    Recommended jellyfin settings
    - under Libraries > Display: enable "Display a folder view to show plain media folders"



---
    
## Notes

    NFS Mount Options:

        - soft: Prevents hanging on NFS server unavailability
        - nfsvers=4.2: Uses modern NFS version
        - x-systemd.automount: Enables automounting
        - noauto: Prevents mount issues during boot

---

    Remember that after setting these permissions:

        - The owner (mediauser) will have full access (read, write, execute)
        - The group (mediagroup) will have full access (read, write, execute)
        - Others will have read and execute permissions but not write


## Notes (for troubleshooting)

    drwxrwsr-x 6 msm shared_access 4096 Feb 12 20:08 backup_media_pool
    
    You're seeing files owned by 'msm' because:
    
        - When you access via Samba, it's creating files as your Windows user account
        - The shared_access group is being applied correctly, but the owner is still 'msm'
    
---

    Docker container storage should also be mapped to the user group, i.e. the dockerfile is inside of, should have the chown changed

## Tips:
- You need to refresh/Rescan library after adding new media, for `Jellyfin` (everytime, else after a period it will start auto rescanning)

## Notes (regarding user)

    Let me help clarify the password requirements for your setup:

        For OpenMediaVault (OMV):
            YES, you need to set a password for mediauser in OMV because:
                It's needed for Samba authentication if you ever need to log in as that user
                It's a system requirement for user creation in OMV
                You can set this through the OMV web interface:
                    Go to Access Rights Management → User
                    Edit mediauser
                    Set a password

        For NixOS:
            NO, you don't need to set a password for mediauser because:
                This user is only needed for file ownership/permissions
                The user won't be logging in directly
                You can configure it in your NixOS configuration like this:

                    users.users.mediauser = {
                        uid = 1500;
                        group = "shared_access";
                        isSystemUser = true;  # Mark as system user
                        createHome = false;   # No home directory needed
                        hashedPassword = null; # No password needed
                    };

                This setup means:

                    OMV: mediauser has a password for potential Samba/system authentication
                    NixOS: mediauser exists just for file ownership, no password needed
                    You'll continue using your main user (MSM74588) for actual operations

```
msm (you) → runs Docker → Container runs internally as UID 1500:1500
```