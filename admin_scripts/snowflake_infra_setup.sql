--define variables
--------------------------------------------
SET db_dev = 'dbt_dev';
SET db_test = 'dbt_test';
SET db_prod = 'dbt_prod';

SET role_dev = 'dbt_dev_role';
SET role_test = 'dbt_test_role';
SET role_prod = 'dbt_prod_role';

set dev_test_wh ='dbt_dev_test_wh';
set dev_test_wh_size = 'XSMALL';
set prod_wh ='dbt_prod_wh';
set prod_wh_size = 'XSMALL';

-------------------------------------------
-- dbt roles
-------------------------------------------
USE ROLE securityadmin;

CREATE OR REPLACE ROLE ($role_dev);
CREATE OR REPLACE ROLE ($role_test);
CREATE OR REPLACE ROLE ($role_prod);

---------------------------------------------
--create warehouses
----------------------------------------------
USE ROLE accountadmin

CREATE OR REPLACE WAREHOUSE ($dev_test_wh)  
    WAREHOUSE_SIZE = ($dev_test_wh_size)
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60 
    AUTO_RESUME = TRUE 
    MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 1 
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'warehouse for dbt project';

CREATE OR REPLACE WAREHOUSE ($prod_wh)  
    WAREHOUSE_SIZE = ($prod_wh_size)
    WAREHOUSE_TYPE = 'standard'
    AUTO_SUSPEND = 60 
    AUTO_RESUME = TRUE 
    MIN_CLUSTER_COUNT = 1 
    MAX_CLUSTER_COUNT = 1 
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'warehouse for dbt project';

GRANT ALL ON WAREHOUSE ($dbt_dev_test_wh)  TO ROLE ($role_dev);
GRANT ALL ON WAREHOUSE ($prod_wh) TO ROLE ($role_prod);

----------------------------------------------------
-- create db and schemas
----------------------------------------------------
USE ROLE sysadmin;

CREATE OR REPLACE DATABASE ($db_dev);
CREATE OR REPLACE DATABASE ($db_test);
CREATE OR REPLACE DATABASE ($db_prod);

CREATE SCHEMA ($db_dev).integrations;
CREATE SCHEMA ($db_test).integrations;
CREATE SCHEMA ($db_prod).integrations;
CREATE SCHEMA ($db_dev).config;
CREATE SCHEMA ($db_test).config;
CREATE SCHEMA ($db_prod).config;

GRANT ALL ON DATABASE ($db_dev) TO ROLE ($role_dev);
GRANT ALL ON DATABASE ($db_test) TO ROLE ($role_test);
GRANT ALL ON DATABASE ($db_prod) TO ROLE ($role_prod);

GRANT ALL ON ALL SCHEMAS IN DATABASE ($db_dev) TO ROLE ($role_dev);
GRANT ALL ON ALL SCHEMAS IN DATABASE ($db_test) TO ROLE ($role_test);
GRANT ALL ON ALL SCHEMAS IN DATABASE ($db_prod) TO ROLE ($role_prod);

-------------------------------------------
USE ROLE securityadmin;
--To grant privileges to create a dbt project object, including deploying from within a workspace:
GRANT CREATE DBT PROJECT ON SCHEMA ($db_dev).config TO ROLE ($role_dev);
GRANT CREATE DBT PROJECT ON SCHEMA ($db_test).config TO ROLE ($role_test);
GRANT CREATE DBT PROJECT ON SCHEMA ($db_prod).config TO ROLE ($role_prod);

--To grant privileges to alter or drop (delete) a dbt project object, including connecting a workspace to a dbt project object:
GRANT OWNERSHIP ON DBT PROJECT dbt_project_2 TO ROLE ($role_dev);
GRANT OWNERSHIP ON DBT PROJECT dbt_project_2 TO ROLE ($role_test);
GRANT OWNERSHIP ON DBT PROJECT dbt_project_2 TO ROLE ($role_prod);

--GRANT USAGE ON DBT PROJECT my_dbt_project_object TO ROLE my_role
GRANT USAGE ON DBT PROJECT dbt_project_2 TO ROLE ($role_dev);
GRANT USAGE ON DBT PROJECT dbt_project_2 TO ROLE ($role_test);
GRANT USAGE ON DBT PROJECT dbt_project_2 TO ROLE ($role_prod);


------------------------------------------- Please replace with your dbt user password
CREATE OR REPLACE USER dbt_user PASSWORD = "Project2";

GRANT ROLE dbt_dev_role,dbt_prod_role TO USER dbt_user;
GRANT ROLE dbt_dev_role,dbt_prod_role TO ROLE sysadmin;

-------------------------------------------
Create API integrations
-------------------------------------------

--create a secret for GitHub
USE ($db_dev).integrations;
CREATE OR REPLACE SECRET ($db_dev).integrations.tb_dbt_git_secret
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

