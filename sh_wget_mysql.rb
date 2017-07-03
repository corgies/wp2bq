require 'io/console'

# https://dumps.wikimedia.org/jawiki/20170620/jawiki-20170620-externallinks.sql.gz
# https://dumps.wikimedia.org/jawiki/20170620/jawiki-20170620-iwlinks.sql.gz
# https://dumps.wikimedia.org/jawiki/20170620/jawiki-20170620-page.sql.gz

print "Input Target Dump lang (e.g. 'jawiki'): "
lang_w = gets.chomp
print "Input Target Dump YYMMDD (e.g. '20170620'): "
yymmdd = gets.chomp

print "Input MySQL User name: "
mysql_u = gets.chomp
print "Input MySQL password: "
mysql_p = STDIN.noecho &:gets
mysql_p.chomp!
print "Input MySQL Database name: "
mysql_d = gets.chomp

if mysql_p.length == 0
  mysql_command_base = "mysql -u #{mysql_u} -D #{mysql_d}"
else
  mysql_command_base = "mysql -u #{mysql_u} -p #{mysql_p} -D #{mysql_d}"
end

base_uri = 'https://dumps.wikimedia.org/' + lang_w + '/' + yymmdd + '/'
lang = lang_w.sub('wiki', '')

sh_filepath = "./step1_#{lang_w}_#{yymmdd}.sh"

filename_prefix = lang_w + '-' + yymmdd
filename_externallinks = "#{filename_prefix}-externallinks.sql.gz"
filename_iwlinks = "#{filename_prefix}-iwlinks.sql.gz"
filename_page = "#{filename_prefix}-page.sql.gz"

externallinks_uri = base_uri + filename_externallinks
iwlinks_uri = base_uri + filename_iwlinks
page_uri = base_uri + filename_page

File.open(sh_filepath, 'w'){|file|
  file.puts 'cd /tmp;'

  file.puts ""
  file.puts "# Wget"
  file.puts 'echo "START Download Files...";'
  file.puts "wget #{externallinks_uri};"
  file.puts "wget #{iwlinks_uri}";
  file.puts "wget #{page_uri}";
  file.puts 'echo "...DONE!"'

  file.puts ""
  file.puts "# MySQL"
  #  file.puts 'echo "START Importing Files to MySQL...";'
  #  file.puts "mysql.server restart;"

  file.puts "echo \"Importing #{filename_externallinks} to Database\";"
  file.puts "pv ./#{filename_externallinks} | gzcat | #{mysql_command_base} && #{mysql_command_base} -B -e \"ALTER TABLE externallinks RENAME TO externallinks_#{yymmdd}\" && echo \"DONE: ALTER TABLE externallinks RENAME TO externallinks_#{yymmdd}\";"

  file.puts "echo \"Importing #{filename_iwlinks} to Database\";"
  file.puts "pv ./#{filename_iwlinks} | gzcat | #{mysql_command_base} && #{mysql_command_base} -B -e \"ALTER TABLE iwlinks RENAME TO iwlinks_#{yymmdd}\" && echo \"DONE: ALTER TABLE iwlinks RENAME TO iwlinks_#{yymmdd}\";"

  file.puts "pv ./#{filename_page} | gzcat | #{mysql_command_base} && #{mysql_command_base} -B -e \"ALTER TABLE page RENAME TO page_#{yymmdd}\" && echo \"DONE: ALTER TABLE page RENAME TO page_#{yymmdd}\";"
  file.puts 'echo "DONE: Import Files to MySQL"'

  file.puts "echo \"*Remove Files...\";"
  file.puts "echo \"*remove #{filename_externallinks}...\";"
  file.puts "rm /tmp/#{filename_externallinks};"
  file.puts "echo \"*remove #{filename_iwlinks}...\";"
  file.puts "rm /tmp/#{filename_iwlinks};"
  file.puts "echo \"*remove #{filename_page}...\""
  file.puts "rm /tmp/#{filename_page};"
  file.puts "echo \"*ALL DONE\!\!;\""
}

puts "Wrote to #{sh_filepath}! ---> Next: \"sh #{sh_filepath}\";"
