-- dbt roles
-------------------------------------------
USE ROLE securityadmin;

CREATE OR REPLACE ROLE dbt_dev_role;
CREATE OR REPLACE ROLE dbt_test_role;
CREATE OR REPLACE ROLE dbt_prod_role;

---------------------------------------------
--create warehouses
----------------------------------------------
USE ROLE accountadmin;

CREATE OR REPLACE WAREHOUSE dbt_dev_test_wh
    WAREHOUSE_SIZE = XSMALL
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'warehouse for dbt project';

CREATE OR REPLACE WAREHOUSE dbt_prod_wh
    WAREHOUSE_SIZE = XSMALL
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'warehouse for dbt project';

GRANT ALL ON WAREHOUSE dbt_dev_test_wh  TO ROLE dbt_dev_role;
GRANT ALL ON WAREHOUSE dbt_prod_wh TO ROLE dbt_prod_role;

----------------------------------------------------
-- create db and schemas
----------------------------------------------------
USE ROLE sysadmin;

CREATE OR REPLACE DATABASE dbt_dev;
CREATE OR REPLACE DATABASE dbt_test;
CREATE OR REPLACE DATABASE dbt_prod;

CREATE SCHEMA dbt_dev.integrations;
CREATE SCHEMA dbt_test.integrations;
CREATE SCHEMA dbt_prod.integrations;
CREATE SCHEMA dbt_dev.config;
CREATE SCHEMA dbt_test.config;
CREATE SCHEMA dbt_prod.config;

GRANT ALL ON DATABASE dbt_dev TO ROLE dbt_dev_role;
GRANT ALL ON DATABASE dbt_test TO ROLE dbt_test_role;
GRANT ALL ON DATABASE dbt_prod TO ROLE dbt_prod_role;

GRANT ALL ON ALL SCHEMAS IN DATABASE dbt_dev TO ROLE dbt_dev_role;
GRANT ALL ON ALL SCHEMAS IN DATABASE dbt_test TO ROLE dbt_test_role;
GRANT ALL ON ALL SCHEMAS IN DATABASE dbt_prod TO ROLE dbt_prod_role;

-------------------------------------------
USE ROLE securityadmin;
--To grant privileges to create a dbt project object, including deploying from within a workspace:
GRANT CREATE DBT PROJECT ON SCHEMA dbt_dev.config TO ROLE dbt_dev_role;
GRANT CREATE DBT PROJECT ON SCHEMA dbt_test.config TO ROLE dbt_test_role;
GRANT CREATE DBT PROJECT ON SCHEMA dbt_prod.config TO ROLE dbt_prod_role;

--To grant privileges to alter or drop (delete) a dbt project object, including connecting a workspace to a dbt project object:
GRANT OWNERSHIP ON DBT PROJECT dbt_project_2 TO ROLE dbt_dev_role;
GRANT OWNERSHIP ON DBT PROJECT dbt_project_2 TO ROLE dbt_test_role;
GRANT OWNERSHIP ON DBT PROJECT dbt_project_2 TO ROLE dbt_prod_role;

--GRANT USAGE ON DBT PROJECT my_dbt_project_object TO ROLE my_role
GRANT USAGE ON DBT PROJECT dbt_project_2 TO ROLE dbt_dev_role;
GRANT USAGE ON DBT PROJECT dbt_project_2 TO ROLE dbt_test_role;
GRANT USAGE ON DBT PROJECT dbt_project_2 TO ROLE dbt_prod_role;


------------------------------------------- Please replace with your dbt user password
CREATE OR REPLACE USER dbt_user PASSWORD = "Project2";

GRANT ROLE dbt_dev_role,dbt_prod_role TO USER dbt_user;
GRANT ROLE dbt_dev_role,dbt_prod_role TO ROLE sysadmin;

-------------------------------------------
Create API integrations
-------------------------------------------

--create a secret for GitHub
USE dbt_dev.integrations;
CREATE OR REPLACE SECRET dbt_dev.integrations.tb_dbt_git_secret
  TYPE = password
  USERNAME = 'mehdee4'
  PASSWORD = 'veryDifficultPassword';

--create an API integration for GitHub that uses the secret you just created
CREATE OR REPLACE API INTEGRATION tb_dbt_git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/my-github-account')
  -- Comment out the following line if your forked repository is public
  ALLOWED_AUTHENTICATION_SECRETS = (tasty_bytes_dbt_db.integrations.tb_dbt_git_secret)
  ENABLED = TRUE;


-- Create NETWORK RULE for external access integration

CREATE OR REPLACE NETWORK RULE dbt_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  -- Minimal URL allowlist that is required for dbt deps
  VALUE_LIST = (
    'hub.getdbt.com',
    'codeload.github.com'
    );

-- Create EXTERNAL ACCESS INTEGRATION for dbt access to external dbt package locations

CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION dbt_ext_access
  ALLOWED_NETWORK_RULES = (dbt_network_rule)
  ENABLED = TRUE;