mkdir csvs;
for i in `ls -1 rm5s`; do 
    echo "bin/convert.rm5.to.csv.php rm5s/$i csvs/$i.csv";
    ./bin/convert.rm5.to.csv.php rm5s/$i csvs/$i.csv;
done
