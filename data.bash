#!/bin/bash
# Bash script for automatic metrics' solution computation data. 

for i in {1..30}; do 

    echo Execution $i;
    argos3 -c landmarks.argos;
    
    echo Writing in results file;
    tail -1 output.txt;
    tail -1 output.txt >> results/results.txt;
    
    echo Moving output file;
    mv output.txt results/output-$i.txt;

done

echo Finished!;

exit 0