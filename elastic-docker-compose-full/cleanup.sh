#!/bin/bash
# Elasticsearch Docker Compose Cleanup Script
# This script helps clean up Docker resources and data

set -e

echo "Elasticsearch Docker Compose Cleanup Script"
echo "============================================="

# Function to stop and remove containers
cleanup_containers() {
    echo "Stopping and removing containers..."
    
    # Stop single node setup
    if [ -f "docker-compose.yml" ]; then
        echo "Cleaning up single node setup..."
        docker-compose down -v 2>/dev/null || true
    fi
    
    # Stop cluster setup
    if [ -f "docker-compose-cluster.yml" ]; then
        echo "Cleaning up cluster setup..."
        docker-compose -f docker-compose-cluster.yml down -v 2>/dev/null || true
    fi
    
    # Stop security setup
    if [ -f "docker-compose-security.yml" ]; then
        echo "Cleaning up security setup..."
        docker-compose -f docker-compose-security.yml down -v 2>/dev/null || true
    fi
    
    echo "Containers cleaned up."
}

# Function to clean up volumes
cleanup_volumes() {
    echo "Cleaning up Docker volumes..."
    docker volume ls -q | grep -E "(elastic|es-data)" | xargs -r docker volume rm 2>/dev/null || true
    echo "Volumes cleaned up."
}

# Function to clean up networks
cleanup_networks() {
    echo "Cleaning up Docker networks..."
    docker network ls -q | xargs -r docker network inspect | \
        jq -r '.[] | select(.Name | startswith("elastic")) | .Name' | \
        xargs -r docker network rm 2>/dev/null || true
    echo "Networks cleaned up."
}

# Function to clean up data directories
cleanup_data() {
    echo "Cleaning up data directories..."
    if [ -d "data" ]; then
        echo "Removing data directory..."
        rm -rf data/
    fi
    echo "Data directories cleaned up."
}

# Function to clean up certificates
cleanup_certs() {
    echo "Cleaning up certificates..."
    if [ -d "certs" ]; then
        echo "Removing certs directory..."
        rm -rf certs/
    fi
    echo "Certificates cleaned up."
}

# Main menu
show_menu() {
    echo ""
    echo "Select cleanup option:"
    echo "1) Stop containers only"
    echo "2) Stop containers and remove volumes"
    echo "3) Full cleanup (containers, volumes, networks, data)"
    echo "4) Clean data directories only"
    echo "5) Clean certificates only"
    echo "6) Exit"
    echo ""
}

# Main execution
main() {
    show_menu
    read -p "Enter your choice [1-6]: " choice
    
    case $choice in
        1)
            cleanup_containers
            ;;
        2)
            cleanup_containers
            cleanup_volumes
            ;;
        3)
            cleanup_containers
            cleanup_volumes
            cleanup_networks
            cleanup_data
            cleanup_certs
            ;;
        4)
            cleanup_data
            ;;
        5)
            cleanup_certs
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please select 1-6."
            main
            ;;
    esac
    
    echo ""
    echo "Cleanup completed successfully!"
}

# Run main function
main