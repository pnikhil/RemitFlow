rootProject.name = "RemitFlow"

include("config-server")
include("discovery-service")
include("gateway-service")
include("transaction-orchestrator-service")
include("banking-partner-service")
include("fraud-detection-service")
include("currency-exchange-service")
include("audit-compliance-service")
include("shared-libraries:common-dto")
include("shared-libraries:security-utils")
include("shared-libraries:messaging-contracts")
