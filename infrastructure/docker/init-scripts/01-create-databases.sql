-- Create separate databases for each service
CREATE DATABASE transactions;
CREATE DATABASE banking;
CREATE DATABASE fraud;
CREATE DATABASE exchange;
CREATE DATABASE audit;
CREATE DATABASE config_server;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE transactions TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE banking TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE fraud TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE exchange TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE audit TO moneyplatform;
GRANT ALL PRIVILEGES ON DATABASE config_server TO moneyplatform;
