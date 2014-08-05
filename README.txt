
The DB.pm needs to be inside a directory called "GUI" (it is part of the requirements as per the package name). 
Algorithm I followed is this: 

1. Take data from mailing table and insert it into report table with current date. The report table needs to be created in the DB (sql-command and schema in new_table.txt file)

2. Look at latest data and consider that as the count of that particular domain. 

3. Find the top-50 domains based on this count and then sort it based on %-change in 30 days. 

4. Here if it is a new domain and did not have entry 30-days back, then it is sorted based on its current count and all such new domains are dumped first. 

5. Rest of the domains are sorted after that. 

I have tested the scripts with multiple cases in my local runs and everything is working fine. 

