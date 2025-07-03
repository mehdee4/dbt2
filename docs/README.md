## Overview

In dbt there is a very nice feature that will help aligning column descriptions across models and avoid repetitions, through the use of the doc function. After identifying the most recurring fields in your models, you can create one or more markdown files (perhaps one file per topic/domain) in the docs folder inside the dbt project folder. In these files, list the fields together with their descriptions.

#example: 
        ## customer_id

       # {% docs customers_test__customer_id_test %}
        #The unique identifier assigned to each customer in numeric format.
        #{% enddocs %}

        ## customer_code

        #{% docs customers_test__customer_code_test %}
        #The unique identifier assigned to each customer in alphanumeric format.
        #{% enddocs %}

#At this point you can simply reference to this file in the .yml file of any model. Like so:

      #   columns:
      #- name: customer_id
       # description: '{{ doc("customers__customer_id") }}'