## Overview
custom macros (sql+jinja codes) for Snowflake object creation and management

### Directory Structure

    - Access_management
        -schema_access_grants.sql
            - creates a dedicated role and grants for a given schema
        - custom_schema_override.sql    
            - Macro used to generate schema and override the default schema
    - Object creation 
        - create_snowflake_file_formats.sql
            - Macro to create file formats in snowflake
        - create_snowflake_stages.sql
            - Macro to create snowflake stages
    - Periodic check
        - db_objects.cleanup.sql
            - identify database tables/views that were created by dbt but are no longer in use