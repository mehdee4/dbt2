## Overview

    Considering that the dbt run task will not build whatever is being stored in that folder, this become a good shelter for:

        - models that don’t need to run anymore but that deserve to be archived somewhere
        - sql queries or scripts that served ad-hoc analyses
        - queries or models that are in a transition phase to be integrate in your dbt project

    while dbt will not materialise the content of this folder, it will still compile it. This means that if there is an issue for example with a ref/source function in a query stored in the analyses folder, it will throw an error.

    To avoid having to worry about this
        - add a config block to disable that model from being compiled. Like so:
        {{ config(enabled = false) }}
