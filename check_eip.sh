#!/bin/bash

# Set AWS profile, output format, and default region
AWS_PROFILE="xxxx"
OUTPUT_FORMAT="json"
DEFAULT_REGION="us-east-1"  # Set a default region for initial commands

# Get all available regions
REGIONS=$(aws ec2 describe-regions --region $DEFAULT_REGION --output text --query 'Regions[*].RegionName' --profile $AWS_PROFILE)

# Initialize counters
TOTAL_EIP_COUNT=0
TOTAL_UNUSED_EIP_COUNT=0

echo "Listing Elastic IPs in all available AWS regions..."

# Loop through each region and list the EIPs
for REGION in $REGIONS; do
    echo "--------------------------------"
    echo "Region: $REGION"
    
    # Get the list of Elastic IPs in the region
    EIPS=$(aws ec2 describe-addresses --region $REGION --output $OUTPUT_FORMAT --query 'Addresses[*].{PublicIp:PublicIp, InstanceId:InstanceId, NetworkInterfaceId:NetworkInterfaceId, AllocationId:AllocationId}' --profile $AWS_PROFILE)
    
    # Count the number of EIPs in the region
    EIP_COUNT=$(echo $EIPS | jq '. | length')
    TOTAL_EIP_COUNT=$((TOTAL_EIP_COUNT + EIP_COUNT))
    
    # Initialize region-specific unused IP count
    UNUSED_EIP_COUNT=0
    
    echo "Number of Elastic IPs: $EIP_COUNT"
    
    if [ "$EIP_COUNT" -gt 0 ]; then
        echo "Elastic IPs:"
        echo $EIPS | jq -r '.[] | "Public IP: \(.PublicIp), Instance ID: \(.InstanceId // "N/A"), Network Interface ID: \(.NetworkInterfaceId // "N/A")"'
        
        # Find and count unused EIPs (where both InstanceId and NetworkInterfaceId are null)
        UNUSED_EIPS=$(echo $EIPS | jq -r '.[] | select(.InstanceId == null and .NetworkInterfaceId == null) | "Public IP: \(.PublicIp), Allocation ID: \(.AllocationId)"')
        UNUSED_EIP_COUNT=$(echo "$UNUSED_EIPS" | wc -l)
        TOTAL_UNUSED_EIP_COUNT=$((TOTAL_UNUSED_EIP_COUNT + UNUSED_EIP_COUNT))
        
        if [ "$UNUSED_EIP_COUNT" -gt 0 ]; then
            echo "Unused Elastic IPs:"
            echo "$UNUSED_EIPS"
        else
            echo "No unused Elastic IPs in this region."
        fi
    else
        echo "No Elastic IPs found in this region."
    fi
done

echo "--------------------------------"
echo "Total Elastic IPs across all regions: $TOTAL_EIP_COUNT"
echo "Total unused Elastic IPs across all regions: $TOTAL_UNUSED_EIP_COUNT"
