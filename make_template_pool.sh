#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

# Create the main backup directory
echo "Creating main backup directory..."
mkdir -p backup_media_pool

# Create the three main sub-folders
echo "Creating main sub-folders..."
mkdir -p backup_media_pool/{phone,pc,camera,others}

# Create sub-folders inside the phone directory
echo "Creating phone sub-folders..."
mkdir -p backup_media_pool/phone/{camera,instagram,twitter,downloads}

# Create sub-folders inside the pc directory
echo "Creating pc sub-folders..."
mkdir -p backup_media_pool/pc/{screenshots,others}

# Create sub-folders inside the camera directory
echo "Creating camera sub-folders..."
mkdir -p backup_media_pool/camera

echo "Directory structure created successfully!"

# Display the created structure using tree-like format
echo -e "\nCreated directory structure:"
echo "backup_media_pool"
echo "├── phone"
echo "│   ├── camera"
echo "│   ├── instagram"
echo "│   ├── twitter"
echo "│   └── downloads"
echo "├── pc"
echo "│   ├── screenshots"
echo "│   └── others"
echo "├── camera"
echo "└── others"