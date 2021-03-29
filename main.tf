data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

resource "random_string" "string" {
  length  = 15
  special = false
  upper   = false
}

resource "azurerm_servicebus_namespace" "main" {
  name                = var.name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  sku                 = var.sku
  capacity            = var.capacity
  tags                = var.tags
}

resource "azurerm_servicebus_namespace_authorization_rule" "main" {
  #for_each = local.authorization_rules
  for_each = { for authorization_rules in local.authorization_rules : authorization_rules.name => authorization_rules }

  name                = each.value.name
  namespace_name      = azurerm_servicebus_namespace.main.name
  resource_group_name = data.azurerm_resource_group.main.name

  listen = contains(each.value.rights, "listen") ? true : false
  send   = contains(each.value.rights, "send") ? true : false
  manage = contains(each.value.rights, "manage") ? true : false
}

resource "azurerm_servicebus_topic" "main" {
  #for_each = local.topics
  for_each = { for topics in local.topics : topics.name => topics }

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.main.name
  namespace_name      = azurerm_servicebus_namespace.main.name

  status                       = each.value.status
  auto_delete_on_idle          = each.value.auto_delete_on_idle
  default_message_ttl          = each.value.default_message_ttl
  enable_batched_operations    = each.value.enable_batched_operations
  enable_express               = each.value.enable_express
  enable_partitioning          = each.value.enable_partitioning
  max_size_in_megabytes        = each.value.max_size
  requires_duplicate_detection = each.value.enable_duplicate_detection
  support_ordering             = each.value.enable_ordering

  duplicate_detection_history_time_window = each.value.duplicate_detection_history_time_window
}

resource "azurerm_servicebus_topic_authorization_rule" "main" {
  #for_each = local.topic_authorization_rules
  for_each = { for topic_authorization_rules in local.topic_authorization_rules : join("-", [topic_authorization_rules.topic_name, topic_authorization_rules.name]) => topic_authorization_rules }

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.main.name
  namespace_name      = azurerm_servicebus_namespace.main.name
  topic_name          = each.value.topic_name

  listen = contains(each.value.rights, "listen") ? true : false
  send   = contains(each.value.rights, "send") ? true : false
  manage = contains(each.value.rights, "manage") ? true : false

  depends_on = [azurerm_servicebus_topic.main]
}

resource "azurerm_servicebus_subscription" "main" {
  #for_each = local.topic_subscriptions
  for_each = { for topic_subscriptions in local.topic_subscriptions : join("-", [topic_subscriptions.topic_name, topic_subscriptions.name]) => topic_subscriptions }

  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.main.name
  namespace_name      = azurerm_servicebus_namespace.main.name
  topic_name          = each.value.topic_name

  max_delivery_count        = each.value.max_delivery_count
  auto_delete_on_idle       = each.value.auto_delete_on_idle
  default_message_ttl       = each.value.default_message_ttl
  lock_duration             = each.value.lock_duration
  enable_batched_operations = each.value.enable_batched_operations
  requires_session          = each.value.enable_session
  forward_to                = each.value.forward_to

  dead_lettering_on_message_expiration = each.value.enable_dead_lettering_on_message_expiration

  depends_on = [azurerm_servicebus_topic.main]
}

resource "azurerm_servicebus_subscription_rule" "main" {
  #for_each = local.topic_subscription_rules
  for_each = { for topic_subscription_rules in local.topic_subscription_rules : join("-", [topic_subscription_rules.topic_name, topic_subscription_rules.subscription_name, topic_subscription_rules.name]) => topic_subscription_rules }


  name                = each.value.name
  resource_group_name = data.azurerm_resource_group.main.name
  namespace_name      = azurerm_servicebus_namespace.main.name
  topic_name          = each.value.topic_name
  subscription_name   = each.value.subscription_name
  filter_type         = each.value.sql_filter != "" ? "SqlFilter" : null
  sql_filter          = each.value.sql_filter
  action              = each.value.action

  depends_on = [azurerm_servicebus_subscription.main]
}