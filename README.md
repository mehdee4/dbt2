###  Overview


This dbt project (dbt_project_2) is designed to manage and transform snowflake objects. 
Managed objects are as follow:

    - Schemas
    - File formats
    - Stages
    - Rolle-based access management
    - Table/view transformation and model creation
        - loading data from datalake to snowflake via external tables
            - Hosting data in the 'RAW' layer
            - Basic flattening/transformation in the 'STG' layer
            - Heavy transfomation and re-useable model under 'INT' layer
            - Publish models under 'MART' layer
        - History data AND slowly changing dimensions type 2 in 'SNAPSHOT' layer
        - seeds (static data) -- loading static data
            - can be used also as control tables

The following are NOT currently managed by this DBT project
    - Storge integration with data lakes
    - Warehouse creation 
    - Database creation 
    - Data shares


### Key Features

- **Stage and File Format Management:**  
  Macros (under the macro directory) are included to automatically create and manage Snowflake external stages and file formats, based on definitions in `dbt_project.yml`.


- **Rolle-based access management:**  
  Post-hook macros are used to automate schema role grants and ensure that file formats and stages are always up to date after model runs.

### Directory Structure

- `dbt_project.yml`  
    - main project configuration, including variables for file formats and stages
    - Schema creation, materialization types etc. are all defined in this file. 
        - variables 
            to define file formats, and stages

- `macros/`    
    – custom macros (sql+jinja codes) for Snowflake object creation and management
    [Read more](macros/readme.md)


- `seeds/` 
      Seed files are loaded into the `sources` schema, making it easy to bootstrap reference data.
        – CSV files for seed
            - Seeds need a correspoinding table to be defined under source 

- `snapshots/` 
        – history data and snapshot definitions for slowly changing dimensions

- `analyses/`
    - Models that are NOT materialized by DBT
    [Read more](analyses/readme.md)

- `docs/` 
        - re-useable definitions to be used again an again
        [Read more](docs/readme.md)

- `models/` 
        – dbt models organized by domain and stage
        [Read more](models/readme.md)

# Running the Project

- **important dbt commands:** 

Run/refresh external source tables
    - dbt run-operation stage_external_sources

run/re-create file formats
    - dbt run-operation create_snowflake_file_formats --args '{target_database_name: DBT_DEV, target_schema_name: CONFIG}'

run/re-create stages
    - dbt run-operation create_snowflake_stages --args '{target_database_name: DBT_DEV, target_schema_name: CONFIG}'

run all models
    - dbt run 
run an specific model/directory
    - dbt run --select <model name> 
run test
    - dbt test
open documentation
    - dbt docs serve # 

- **Other commands:** 
open the profile file
    code ~/.dbt/profiles.yml 
activate virtual environment
    source .venv_dbt/bin/activate

