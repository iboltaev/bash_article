# reports - tables                                                                                                                     
grep -r "\"table\":" projects/*/reports/* | sed 's/:/ /g' | awk '{print $1 " " $3}' | sed 's/[\r\n",:]//g' | grep "\s[A-Za-z0-9]" | sort -k 1b,1 | uniq > report_tables

# reports - dates                                                                                                                      
grep -r "\"created_date\":" projects/*/reports/* | sed 's/:/ /g' | awk '{print $1 " " $3"T"$4":"$5":"$6}' | sed 's/[\r\n\t",]//g' | sort -k 1b,1 | uniq > report_dates

# reports - tables & dates                                                                                                             
join report_tables report_dates | awk '{print $1"#"$2 " " $3}' > report_table_date

# schema - configs                                                                                                                     
grep -r "schema\":" ~/projects/*/conf/* | sed 's/:/ /g' | awk '{print $3 " " $1}' | sed 's/[\r\n":,]//g' | sort -k 1b,1 | uniq > schema_configs

# config - schemas                                                                                                                     
cat schema_configs | awk '{print $2 " " $1}' | sort -k 1b,1 | uniq > config_schemas

# configs - reports                                                                                                                    
cat schema_configs | awk '{print $2}' | sort | uniq | grep ".conf$" | while read line; do re="^(.*)/conf/.*$"; if [[ $line =~ $re ]]; then pdir=${BASH_REMATCH[1]}/reports; re2=".*/([^/\.]*)\..*"; if [[ $line =~ $re2 ]]; then run=${BASH_REMATCH[1]}; reps=$(find $pdir/$run -name *.json); for r in $reps; do echo $line $r ; done ; fi ; fi ;done | grep -v run_log | sort -k 1b,1 > config_reports

# schemas - tables                                                                                                                     
cat schema_configs | awk '{print $1}' | sort | uniq | grep "[A-Za-z0-9]" | sed 's/^/path_in_hive/g' | sed 's/$/\.db/g' | xargs -n1 -I dr hdfs dfs -ls dr | sed 's/\// /g' | sed 's/\.db//g' | awk '{print $12 " " $13 " " $6"T"$7}' | sort -k 1b,1 | uniq > schema_tables

# configs - tables                                                                                                                     
join schema_configs schema_tables | awk '{print $2 " " $3 " " $4}' | sort -k 1b,1 | uniq > config_tables

# reports - tables hive dates
join config_reports config_tables | awk '{print $2"#"$3 " " $4}' | sort -k 1b,1 > report_table_hive_dates

# final!
join report_table_date report_table_hive_dates | sed 's/#/ /g' | awk '{if ($3<$4) print $1}' | sort | uniq > outdated_reports
