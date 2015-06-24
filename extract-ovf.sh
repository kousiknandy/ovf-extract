#!/bin/bash

CPU=$(cat <<EOF | xmllint --shell $1 
	setns ovf=http://schemas.dmtf.org/ovf/envelope/1
	setns rasd=http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData
	xpath /ovf:Envelope/ovf:VirtualSystem/ovf:VirtualHardwareSection/ovf:Item/rasd:VirtualQuantity/text()[../../rasd:ResourceType/text() = "3"]
EOF
)
echo $CPU | grep -oE "content=[^ ]*" | sed 's/content=//' | sed 's/^/CPU=/'

MEMORY=$(cat <<EOF | xmllint --shell $1
	setns ovf=http://schemas.dmtf.org/ovf/envelope/1
	setns rasd=http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData
	xpath /ovf:Envelope/ovf:VirtualSystem/ovf:VirtualHardwareSection/ovf:Item/rasd:VirtualQuantity/text()[../../rasd:ResourceType/text() = "4"] | /ovf:Envelope/ovf:VirtualSystem/ovf:VirtualHardwareSection/ovf:Item/rasd:AllocationUnits/text()[../../rasd:ResourceType/text() = "4"]
EOF
)
echo $MEMORY | grep -oE "content=[^ ]*" | sort | tr -d \\n  | sed 's/content=//g' | sed 's/^/MEMORY=/'
echo

DISKREF=$(cat <<EOF | xmllint --shell $1
	setns ovf=http://schemas.dmtf.org/ovf/envelope/1
	setns rasd=http://schemas.dmtf.org/wbem/wscim/1/cim-schema/2/CIM_ResourceAllocationSettingData
	xpath /ovf:Envelope/ovf:VirtualSystem/ovf:VirtualHardwareSection/ovf:Item/rasd:HostResource/text()[../../rasd:ResourceType/text() = "17"]
EOF
)

DISKNAME=($(echo $DISKREF | grep -oE "ovf:/disk/[^ ]*" | sort | sed 's/ovf:\/disk\///g' | tr '\n' ' '))

for disk in "${DISKNAME[@]}"
do
DISKFILE=$(cat <<EOF | xmllint --shell $1
	setns ovf=http://schemas.dmtf.org/ovf/envelope/1
	xpath /ovf:Envelope/ovf:DiskSection/ovf:Disk/@ovf:fileRef[../@ovf:diskId = "$disk"]
EOF
)

FILEREF=$(echo $DISKFILE | grep -oE "content=[^ ]*" | sed 's/content=//g')
IMAGE=$(cat <<EOF | xmllint --shell $1
	setns ovf=http://schemas.dmtf.org/ovf/envelope/1
	xpath /ovf:Envelope/ovf:References/ovf:File/@ovf:href[../@ovf:id = "$FILEREF"]
EOF
)

echo $IMAGE| grep -oE "content=[^ ]*" | sed 's/content=//g' | sed 's/^/DISK=/'
done

