# wp2bq
Import Wikipedia Dump Data Files(externalinks.sql, iwlinks.sql, and page.sql) to Google BigQuery

# How to Use

## Step1. sh_wget_mysql.rb

Download dump files by using wget and import to MySQL

**$ ruby sh_wget_mysql.rb**

Input Target Dump lang (e.g. 'jawiki'): **jawiki**

Input Target Dump YYMMDD (e.g. '20170620'): **20170701**

Input MySQL User name: **test**

Input MySQL password: ********

Input MySQL Database name:**ja_wikipedia_dump**

Wrote to ./step1_jawiki_20170701.sh! ---> Next: "sh ./step1_jawiki_20170701.sh";

**$ sh ./step1_jawiki_20170701.sh**

## Step2. ruby sh_bq_importer.rb

Export csv files from MySQL and Import to BigQuery

**$ ruby ruby sh_bq_importer.rb**

Input target lang (e.g. 'jawiki'): **jawiki**

Input target yymmdd (e.g. '20170320'): **20170701**

Input GSC instance_name name (e.g. "gs://hogehoge/"): **gs://instance-name/**

Input MySQL User name: **test**

Input MySQL password: Input MySQL Database name: **ja_wikipedia_dump**

Wrote to ./step2_jawiki_20170701.sh! ---> Next: "sh ./step2_jawiki_20170701.sh";

**$ sh ./step2_jawiki_20170701.sh**
