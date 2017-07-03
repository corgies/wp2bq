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

Input gs instance_name name (e.g. "gs://hogehoge/"): **gs://instance-name/**

Input MySQL User name: **test**

Input MySQL password: ********

Input MySQL Database name: **ja_wikipedia_dump**

Wrote to ./step2_jawiki_20170701.sh! ---> Next: "sh ./step2_jawiki_20170701.sh";

**$ sh ./step2_jawiki_20170701.sh**

## Sample: step1_jawiki_20170701.sh
```
cd /tmp;

# Wget
echo "START Download Files...";
wget https://dumps.wikimedia.org/jawiki/20170701/jawiki-20170701-externallinks.sql.gz;
wget https://dumps.wikimedia.org/jawiki/20170701/jawiki-20170701-iwlinks.sql.gz
wget https://dumps.wikimedia.org/jawiki/20170701/jawiki-20170701-page.sql.gz
echo "...DONE!"

# MySQL
echo "Importing jawiki-20170701-externallinks.sql.gz to Database";
pv ./jawiki-20170701-externallinks.sql.gz | gzcat | mysql -u test -p testtest -D ja_wikipedia_dump && mysql -u test -p testtest -D ja_wikipedia_dump -B -e "ALTER TABLE externallinks RENAME TO externallinks_20170701" && echo "DONE: ALTER TABLE externallinks RENAME TO externallinks_20170701";
echo "Importing jawiki-20170701-iwlinks.sql.gz to Database";
pv ./jawiki-20170701-iwlinks.sql.gz | gzcat | mysql -u test -p testtest -D ja_wikipedia_dump && mysql -u test -p testtest -D ja_wikipedia_dump -B -e "ALTER TABLE iwlinks RENAME TO iwlinks_20170701" && echo "DONE: ALTER TABLE iwlinks RENAME TO iwlinks_20170701";
pv ./jawiki-20170701-page.sql.gz | gzcat | mysql -u test -p testtest -D ja_wikipedia_dump && mysql -u test -p testtest -D ja_wikipedia_dump -B -e "ALTER TABLE page RENAME TO page_20170701" && echo "DONE: ALTER TABLE page RENAME TO page_20170701";
echo "DONE: Import Files to MySQL"
echo "*Remove Files...";
echo "*remove jawiki-20170701-externallinks.sql.gz...";
rm /tmp/jawiki-20170701-externallinks.sql.gz;
echo "*remove jawiki-20170701-iwlinks.sql.gz...";
rm /tmp/jawiki-20170701-iwlinks.sql.gz;
echo "*remove jawiki-20170701-page.sql.gz..."
rm /tmp/jawiki-20170701-page.sql.gz;
echo "*ALL DONE!!;"
```

## Sample: step2_jawiki_20170701.sh
```
echo "*Start exporting Data from MySQL to CSV..."
mysql -u test -p testtest -D ja_wikipedia_dump -B -e"SELECT el_id, el_from, el_from_namespace, REPLACE(REPLACE(el_to, '\n', ''), '\r', ''), REPLACE(REPLACE(el_index, '\n', ''), '\r', '') FROM externallinks_20170701 INTO OUTFILE \"/tmp/jawiki_externallinks_20170701.csv\" FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\n';" && gzip /tmp/jawiki_externallinks_20170701.csv;
echo "*Saved as /tmp/jawiki_externallinks_20170701.csv.gz"
mysql -u test -p testtest -D ja_wikipedia_dump -B -e"SELECT * FROM iwlinks_20170701 INTO OUTFILE \"/tmp/jawiki_iwlinks_20170701.csv\" FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\n';" && gzip /tmp/jawiki_iwlinks_20170701.csv;
echo "*Saved as /tmp/jawiki_iwlinks_20170701.csv.gz"
mysql -u test -p testtest -D ja_wikipedia_dump -B -e"SELECT IFNULL(page_id, ''), IFNULL(page_namespace, ''), IFNULL(page_title, ''), IFNULL(page_restrictions, ''), IFNULL(page_counter, ''), IFNULL(page_is_redirect, ''), IFNULL(page_is_new, ''), IFNULL(page_random, ''), IFNULL(page_touched, ''), IFNULL(page_links_updated, ''), IFNULL(page_latest, ''),  IFNULL(page_len, ''), IFNULL(page_content_model, '') FROM page_20170701 INTO OUTFILE \"/tmp/jawiki_page_20170701.csv\" FIELDS TERMINATED BY ',' ENCLOSED BY '\"' ESCAPED BY '\"' LINES TERMINATED BY '\n';" && gzip /tmp/jawiki_page_20170701.csv
echo "*Saved as /tmp/jawiki_page_20170701.csv.gz"

echo "*Copying externallinks_20170701.csv.gz to gs://test/"
gsutil cp /tmp/jawiki_externallinks_20170701.csv.gz gs://test/;
echo "*DONE: Copying Externallinks to gs://test/"

echo "*Copying iwlinks_20170701.csv.gz to gs://test/"
gsutil cp /tmp/jawiki_iwlinks_20170701.csv.gz gs://test/;
echo "*DONE: Copying Iwlinks to gs://test/"

echo "*Copying page_20170701.csv.gz to gs://test/"
gsutil cp /tmp/jawiki_page_20170701.csv.gz gs://test/;
echo "*DONE: Copying Page to gs://test/"

echo "*Start inserting to Bigquery jawiki.externallinks_20170701"
bq load --source_format=CSV jawiki.externallinks_20170701 gs://test/jawiki_externallinks_20170701.csv.gz "el_id:INTEGER,el_from:INTEGER,el_from_namespace:INTEGER,el_to:STRING,el_index:STRING";
echo "*DONE: Bigquery::jawiki.externallinks_20170701"

echo "*Start inserting to Bigquery jawiki.iwlinks_20170701"
bq load --source_format=CSV jawiki.iwlinks_20170701 gs://test/jawiki_iwlinks_20170701.csv.gz "iwl_from:INTEGER,iwl_prefix:STRING,iwl_title:STRING";
echo "*DONE: Bigquery::jawiki.iwlinks_20170701"

echo "*Start inserting to Bigquery jawiki.page_20170701"
bq load --source_format=CSV jawiki.page_20170701 gs://test/jawiki_page_20170701.csv.gz "page_id:INTEGER,page_namespace:INTEGER,page_title:STRING,page_restrictions:STRING,page_counter:INTEGER,page_is_redirect:INTEGER,page_is_new:INTEGER,page_random:FLOAT,page_touched:STRING,page_links_updated:STRING,page_latest:INTEGER,page_len:INTEGER,page_content_model:STRING";
echo "*DONE: Bigquery::jawiki.page_20170701"

echo "*Remove Files...";
echo "*remove jawiki_externallinks_20170701.csv.gz...";
rm /tmp/jawiki_externallinks_20170701.csv.gz;
echo "*remove jawiki_iwlinks_20170701.csv...";
rm /tmp/jawiki_iwlinks_20170701.csv.gz;
echo "*remove jawiki_page_20170701.csv.gz..."
rm /tmp/jawiki_page_20170701.csv.gz;
echo "*ALL DONE!!;"
```
