require 'io/console'

print "Input target lang (e.g. 'jawiki'): "
lang_w = gets.chomp

print "Input target yymmdd (e.g. '20170320'): "
yymmdd = gets.chomp

print 'Input GSC instance_name name (e.g. "gs://hogehoge/"): '
instance_name = gets.chomp

print "Input MySQL User name: "
mysql_u = gets.chomp
print "Input MySQL password: "
mysql_p = STDIN.noecho &:gets
mysql_p.chomp!
print "Input MySQL Database name: "
mysql_d = gets.chomp

lang = lang_w.sub('wiki', '')

sh_filepath = "./step2_#{lang_w}_#{yymmdd}.sh"
if mysql_p.length == 0
  @mysql_command_base = "mysql -u #{mysql_u} -D #{mysql_d}"
else
  @mysql_command_base = "mysql -u #{mysql_u} -p #{mysql_p} -D #{mysql_d}"
end

@filename_externallinks = "#{lang}wiki_externallinks_#{yymmdd}.csv"
@filename_iwlinks = "#{lang}wiki_iwlinks_#{yymmdd}.csv"
@filename_page = "#{lang}wiki_page_#{yymmdd}.csv"

def export_and_gzip(lang, yymmdd, type)
  case type
  when 'externallinks' then
    mysql_command = %Q{#{@mysql_command_base} -B -e"SELECT el_id, el_from, el_from_namespace, REPLACE(REPLACE(el_to, '\\n', ''), '\\r', ''), REPLACE(REPLACE(el_index, '\\n', ''), '\\r', '') FROM externallinks_#{yymmdd} INTO OUTFILE \\"/tmp/#{lang}wiki_externallinks_#{yymmdd}.csv\\" FIELDS TERMINATED BY ',' ENCLOSED BY '\\"' ESCAPED BY '\\"' LINES TERMINATED BY '\\n';"}
    gzip_command = "gzip /tmp/#{@filename_externallinks};"
    result = mysql_command + " && "+ gzip_command
    return result
  # mysql> SELECT REPLACE(REPLACE(el_to, '\n', ''), '\r', '') FROM externallinks_20150301 WHERE el_id = '5316877' INTO OUTFILE '/tmp/c1.txt'; Query OK, 1 row affected (0.01 sec)

  when 'iwlinks' then
    mysql_command = %Q{#{@mysql_command_base} -B -e"SELECT * FROM iwlinks_#{yymmdd} INTO OUTFILE \\"/tmp/#{lang}wiki_iwlinks_#{yymmdd}.csv\\" FIELDS TERMINATED BY ',' ENCLOSED BY '\\"' ESCAPED BY '\\"' LINES TERMINATED BY '\\n';"}
    gzip_command = "gzip /tmp/#{@filename_iwlinks};"
    result = mysql_command + " && " + gzip_command
    return result

  when 'page' then
    mysql_command = %Q{#{@mysql_command_base} -B -e"SELECT IFNULL(page_id, ''), IFNULL(page_namespace, ''), IFNULL(page_title, ''), IFNULL(page_restrictions, ''), IFNULL(page_counter, ''), IFNULL(page_is_redirect, ''), IFNULL(page_is_new, ''), IFNULL(page_random, ''), IFNULL(page_touched, ''), IFNULL(page_links_updated, ''), IFNULL(page_latest, ''),  IFNULL(page_len, ''), IFNULL(page_content_model, '') FROM page_#{yymmdd} INTO OUTFILE \\"/tmp/#{lang}wiki_page_#{yymmdd}.csv\\" FIELDS TERMINATED BY ',' ENCLOSED BY '\\"' ESCAPED BY '\\"' LINES TERMINATED BY '\\n';"}
    gzip_command = "gzip /tmp/#{@filename_page}"
    result = mysql_command + " && " + gzip_command
    return result
  end
end

def cp_to_gcloud(lang, type, yymmdd, instance_name)
  cp_command = "gsutil cp /tmp/#{lang}wiki_#{type}_#{yymmdd}.csv.gz #{instance_name};"
  return cp_command
end

def insert_to_bigquery(lang, type, yymmdd, instance_name)
  bq_load_base = "bq load --source_format=CSV #{lang}wiki.#{type}_#{yymmdd} #{instance_name}#{lang}wiki_#{type}_#{yymmdd}.csv.gz "
  case type
  when 'externallinks' then
    bq_option = %Q{"el_id:INTEGER,el_from:INTEGER,el_from_namespace:INTEGER,el_to:STRING,el_index:STRING";}
    command = bq_load_base + bq_option
    return command
  when 'iwlinks' then
    bq_option = %Q{"iwl_from:INTEGER,iwl_prefix:STRING,iwl_title:STRING";}
    command = bq_load_base + bq_option
    return command
  when 'page' then
    bq_option = %Q{"page_id:INTEGER,page_namespace:INTEGER,page_title:STRING,page_restrictions:STRING,page_counter:INTEGER,page_is_redirect:INTEGER,page_is_new:INTEGER,page_random:FLOAT,page_touched:STRING,page_links_updated:STRING,page_latest:INTEGER,page_len:INTEGER,page_content_model:STRING";}
    command = bq_load_base + bq_option
    return command
  end
end


File.open(sh_filepath, "w"){|file|

  ##### Export Data From MySQL to CSV ######
  export_externallinks = export_and_gzip(lang, yymmdd, 'externallinks')
  export_iwlinks = export_and_gzip(lang, yymmdd, 'iwlinks')
  export_page = export_and_gzip(lang, yymmdd, 'page')

  file.puts 'echo "*Start exporting Data from MySQL to CSV..."'
  file.puts export_externallinks
  file.puts "echo \"*Saved as /tmp/#{lang}wiki_externallinks_#{yymmdd}.csv.gz\""
  file.puts export_iwlinks
  file.puts "echo \"*Saved as /tmp/#{lang}wiki_iwlinks_#{yymmdd}.csv.gz\""
  file.puts export_page
  file.puts "echo \"*Saved as /tmp/#{lang}wiki_page_#{yymmdd}.csv.gz\""
  file.puts ""

  ##### Copy Data to GoogleCloudStorage ######
  cp_to_gcloud_externallinks = cp_to_gcloud(lang, 'externallinks', yymmdd, instance_name)
  file.puts "echo \"*Copying externallinks_#{yymmdd}.csv.gz to #{instance_name}\""
  file.puts cp_to_gcloud_externallinks;
  file.puts "echo \"*DONE: Copying Externallinks to #{instance_name}\""
  file.puts ""

  cp_to_gcloud_iwlinks = cp_to_gcloud(lang, 'iwlinks', yymmdd, instance_name)
  file.puts "echo \"*Copying iwlinks_#{yymmdd}.csv.gz to #{instance_name}\""
  file.puts cp_to_gcloud_iwlinks;
  file.puts "echo \"*DONE: Copying Iwlinks to #{instance_name}\""
  file.puts ""

  cp_to_gcloud_page = cp_to_gcloud(lang, 'page', yymmdd, instance_name)
  file.puts "echo \"*Copying page_#{yymmdd}.csv.gz to #{instance_name}\""
  file.puts cp_to_gcloud_page;
  file.puts "echo \"*DONE: Copying Page to #{instance_name}\""
  file.puts ""

  ##### Import CSV to BigQuery ######
  insert_to_bigquery_externallinks = insert_to_bigquery(lang, 'externallinks', yymmdd, instance_name)
  file.puts "echo \"*Start inserting to Bigquery #{lang}wiki.externallinks_#{yymmdd}\""
  file.puts insert_to_bigquery_externallinks
  file.puts "echo \"*DONE: Bigquery::#{lang}wiki.externallinks_#{yymmdd}\""
  file.puts ""

  insert_to_bigquery_iwlinks = insert_to_bigquery(lang, 'iwlinks', yymmdd, instance_name)
  file.puts "echo \"*Start inserting to Bigquery #{lang}wiki.iwlinks_#{yymmdd}\""
  file.puts insert_to_bigquery_iwlinks
  file.puts "echo \"*DONE: Bigquery::#{lang}wiki.iwlinks_#{yymmdd}\""
  file.puts ""

  insert_to_bigquery_page = insert_to_bigquery(lang, 'page', yymmdd, instance_name)
  file.puts "echo \"*Start inserting to Bigquery #{lang}wiki.page_#{yymmdd}\""
  file.puts insert_to_bigquery_page
  file.puts "echo \"*DONE: Bigquery::#{lang}wiki.page_#{yymmdd}\""
  file.puts ""

  ##### Remove Files #####
  file.puts "echo \"*Remove Files...\";"
  file.puts "echo \"*remove #{@filename_externallinks}.gz...\";"
  file.puts "rm /tmp/#{@filename_externallinks}.gz;"
  file.puts "echo \"*remove #{@filename_iwlinks}...\";"
  file.puts "rm /tmp/#{@filename_iwlinks}.gz;"
  file.puts "echo \"*remove #{@filename_page}.gz...\""
  file.puts "rm /tmp/#{@filename_page}.gz;"
  file.puts "echo \"*ALL DONE\!\!;\""
  file.puts ""
}

puts "Wrote to #{sh_filepath}! ---> Next: \"sh #{sh_filepath}\";"
