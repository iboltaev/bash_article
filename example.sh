# reports - tables
grep -r "\"table\":" projects/*/reports/* | awk '{print $1 " " $3}' | sed 's/[\r\n",:]//g' | grep "\s[A-Za-z0-9]" | sort -k 1b,1 | uniq > report_tables

# reports - dates
grep -r "\"created_date\":" projects/*/reports/* | awk '{print $1 " " $3"T"$4}' | sed 's/[\r\n\t":,]//g' | sort -k 1b,1 | uniq > report_dates

# reports - tables & dates
join report_tables report_dates > report_table_date

# reports - projects & runs
cat report_tables | awk '{print $1}' | sort | uniq | while read line; do re1=".*/projects/([^/]*)/reports/.*"; proj=""; if [[ $line =~ $re1 ]]; then proj=${BASH_REMATCH[1]} ; fi; re2=".*/([^/]*)/[^/]*$"; run=""; if [[ $line =~ $re2 ]]; then run=${BASH_REMATCH[1]} ;fi; echo $line $proj:$run; done | sort -k 1b,1 | uniq > report_project_run

# configs - schemas
grep -r "schema\":" projects/*/conf/* | awk '{print $1 " " $3}' | sed 's/[\r\n\t":,]//g' | sort -k 1b,1 | uniq > config_schemas

# configs - projects & runs
cat config_schemas | awk '{print $1}' | sort | uniq | while read line; do re1=".*/<projects>/([^/]*)/conf/.*"; proj=""; if [[ $line =~ $re1 ]]; then proj=${BASH_REMATCH[1]} ; fi; re2=".*/([^/\.]*)\.[^\.]*$"; run=""; if [[ $line =~ $re2 ]]; then run=${BASH_REMATCH[1]} ;fi; echo $line $proj:$run; done | sort -k 1b,1 | uniq > config_project

# projects & runs - schemas
join config_project config_schemas | awk '{print $2 " " $3}' | sort --version-sort | uniq > project_run_schemas

# schemas - tables
cat config_schemas | awk '{print $2}' | sort | uniq | grep "[A-Za-z0-9]" | sed 's/^/<path_in_hdfs>/g' | sed 's/$/\.db/g' | xargs -n1 -I dr hdfs dfs -ls dr | sed 's/\// /g' | sed 's/\.db//g' | awk '{print $12 " " $13 " " $6"T"$7}' | sort -k 1b,1 | uniq > schema_tables

# schemas - projects & runs
cat project_run_schemas | awk '{print $2 " " $1}' | sort -k 1b,1 > schema_projects

# projects & runs - tables
join schema_projects schema_tables | awk '{print $2 "#" $3 " " $4}' | sort -k 1b,1 | uniq > project_run_table_date

# projects & runs & tables - report date
join report_project_run report_table_date | awk '{print $2"#"$3 " " $1 " " $4}' | sort -k 1b,1 > project_run_report_date

# final!
join project_run_report_date project_run_table_date | awk '{ if ($3<$4) print $2 }' | sort | uniq > outdated_reports
