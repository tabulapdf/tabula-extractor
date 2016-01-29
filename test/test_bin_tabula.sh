ruby bin/tabula test/heuristic-test-set/spreadsheet/tabla_subsidios.pdf --silent -o test.csv
ruby bin/tabula test/heuristic-test-set/spreadsheet/tabla_subsidios.pdf -o test.csv
ruby bin/tabula test/heuristic-test-set/original/bo_page24.pdf -o test.csv
ruby bin/tabula test/heuristic-test-set/original/bo_page24.pdf -o test.csv --format TSV
ruby bin/tabula test/data/campaign_donors.pdf -o test.csv --columns 47,147,256,310,375,431,504 #columns should work
ruby bin/tabula test/data/argentina_diputados_voting_record.pdf --guess -o test.csv --format TSV #should exclude guff
ruby bin/tabula test/data/vertical_rulings_bug.pdf --area 250,0,325,1700 -o test.csv --format TSV #should be only a few lines
