provider "azurerm" {
  version = "=2.0.0"
  features {}

# Crete a Service principle through Azure CLI with, "az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/SUBSCRIPTION_ID""

  subscription_id   =  "cfaa064a-28f3-441f-ae95-9b41bbe55a71"
  client_id         = "a6e63fff-70de-4368-be2b-281ec249c6e4"
  client_secret     = "1tDx5~5RL43Mtcm4481kRT-v9PnF4W.to1"
  tenant_id         = "3cd9c926-06db-4efc-8e86-5ee729381a68"
}
     
# Creating the resource group
  
resource "azurerm_resource_group" "rg" {
 name     = "RG_LAB_AUG2020"
 location = "eastus"
         
  }

# Creating a vNET

  resource "azurerm_virtual_network" "vNET" {
  name                = "VNET_LAB_AUG2020_2"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["192.168.0.0/16"]
  }
  
    
  resource "azurerm_subnet" "subnet" {
  name           = "WEB-SUBNET_2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vNET.name
  address_prefix = "192.168.1.0/24"
  }
  #Error: A resource with the ID "/subscriptions/cfaa064a-28f3-441f-ae95-9b41bbe55a71/resourceGroups/RG_LAB_AUG2020/providers/Microsoft.Network/virtualNetworks/VNET_LAB_AUG2020/subnets/WEB-SUBNET" already exists - to be managed via Terraform this resource needs to be imported into the State. Please see the resource documentation for "azurerm_subnet" for more information.
  # If Any Subnet exist error use below command
  # terraform import azurerm_subnet.subnet /subscriptions/cfaa064a-28f3-441f-ae95-9b41bbe55a71/resourceGroups/RG_LAB_AUG2020/providers/Microsoft.Network/virtualNetworks/VNET_LAB_AUG2020/subnets/WEB-SUBNET   

# Create a Network Security group

  resource "azurerm_network_security_group" "WEBNSG_2" {
  name                = "WEB_NSG_LAB_AUG2020_2"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.rg.name

# Define inbound Rule

  security_rule {
    name                        = "Allow_RDP"
    priority                    = "100"
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "tcp"
    source_port_range           = "*"
    destination_port_range      = "3389"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
  }

  }

# Create a Public IP

 resource "azurerm_public_ip" "PIP_2" {
 name                         = "SRV-PIP_2"
 location                     = "eastus"
 resource_group_name          = azurerm_resource_group.rg.name
 allocation_method            = "Dynamic"
}

# Create a Network interface

resource "azurerm_network_interface" "NIC_2" {
 count               = 1
 name                = "SRVNIC_2${count.index}"
 location            = "eastus"
 resource_group_name = azurerm_resource_group.rg.name

 ip_configuration {
   name                          = "SRV_2-IPConfig"   
   subnet_id                     = azurerm_subnet.subnet.id
   private_ip_address_allocation = "dynamic"
   public_ip_address_id          = azurerm_public_ip.PIP_2.id
 }
}

resource "azurerm_virtual_machine" "VM_2" {
  #count                 = "${var.vm_count}"
  # name                  = "SRV-${count.index + 1}"
  count                 = 1
  name                  = "SRV_2-${count.index}"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.rg.name
  #network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  network_interface_ids = [azurerm_network_interface.NIC_2[count.index].id]
  #vm_size               = "Standard_DS1_v2"
  vm_size               = "Standard_B2s"
  
  #Error: either a `os_profile_linux_config` or a `os_profile_windows_config` must be specified

  os_profile_windows_config { 
    provision_vm_agent = true
}

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "LABWEBSRV02_OS_DISK"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

 os_profile {
    computer_name  = "LABWEBSRV02"
    admin_username = "testvmadmin"
    admin_password = "Testvmadmin@1"
  }
}

