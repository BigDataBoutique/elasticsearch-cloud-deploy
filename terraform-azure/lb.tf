resource "azurerm_public_ip" "clients" {
  count                        = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"
  name                         = "es-${var.es_cluster}-public-ip"
  location                     = "${var.azure_location}"
  resource_group_name          = "${azurerm_resource_group.elasticsearch.name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${azurerm_resource_group.elasticsearch.name}"
}

resource "azurerm_lb" "clients" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"

  location = "${var.azure_location}"
  name = "es-${var.es_cluster}-clients-lb"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  frontend_ip_configuration {
    name = "es-${var.es_cluster}-ip"
    subnet_id = "${azurerm_subnet.elasticsearch_subnet.id}"
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_lb" "clients-public" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"

  location = "${var.azure_location}"
  name = "es-${var.es_cluster}-clients-public-lb"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"

  frontend_ip_configuration {
    name                 = "es-${var.es_cluster}-public-ip"
    public_ip_address_id = "${azurerm_public_ip.clients.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "clients-lb-backend" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"
  name = "es-${var.es_cluster}-clients-lb-backend"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  loadbalancer_id = "${var.associate_public_ip == true ? azurerm_lb.clients-public.id : azurerm_lb.clients.id}"
}

resource "azurerm_lb_probe" "clients-httpprobe" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"
  name = "es-${var.es_cluster}-clients-lb-probe"
  port = 8080
  protocol = "Http"
  request_path = "/status"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
  loadbalancer_id = "${var.associate_public_ip == true ? azurerm_lb.clients-public.id : azurerm_lb.clients.id}"
}

// Kibana, Cerebro and Elasticsearch access - protected by default by the nginx proxy
resource "azurerm_lb_rule" "clients-lb-rule" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"
  name = "es-${var.es_cluster}-clients-lb-rule"
  backend_port = 8080
  frontend_port = 80
  frontend_ip_configuration_name = "${var.associate_public_ip == true ? "es-${var.es_cluster}-public-ip" : "es-${var.es_cluster}-ip"}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.clients-lb-backend.id}"
  protocol = "Tcp"
  loadbalancer_id = "${var.associate_public_ip == true ? azurerm_lb.clients-public.id : azurerm_lb.clients.id}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
}

// Grafana instance, protected by default by their own login screen
resource "azurerm_lb_rule" "clients-lb-rule2" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"
  name = "es-${var.es_cluster}-clients-lb-rule2"
  backend_port = 3000
  frontend_port = 3000
  frontend_ip_configuration_name = "${var.associate_public_ip == true ? "es-${var.es_cluster}-public-ip" : "es-${var.es_cluster}-ip"}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.clients-lb-backend.id}"
  protocol = "Tcp"
  loadbalancer_id = "${var.associate_public_ip == true ? azurerm_lb.clients-public.id : azurerm_lb.clients.id}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
}

// SSH access
resource "azurerm_lb_rule" "clients-lb-rule-ssh" {
  count = "${var.associate_public_ip == "true" && var.clients_count != "0" ? "1" : "0"}"
  name = "es-${var.es_cluster}-clients-lb-rule-ssh"
  backend_port = 22
  frontend_port = 22
  frontend_ip_configuration_name = "${var.associate_public_ip == true ? "es-${var.es_cluster}-public-ip" : "es-${var.es_cluster}-ip"}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.clients-lb-backend.id}"
  protocol = "Tcp"
  loadbalancer_id = "${var.associate_public_ip == true ? azurerm_lb.clients-public.id : azurerm_lb.clients.id}"
  resource_group_name = "${azurerm_resource_group.elasticsearch.name}"
}