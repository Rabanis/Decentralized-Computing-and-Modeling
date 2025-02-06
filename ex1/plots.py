import matplotlib.pyplot as plt
import csv
import  numpy as np
import pandas as pd

ef3 = []
ef7 = []
ef15 = []

with open('ex1_1 Simple MIS-table.csv', 'r') as File:  
    lines = csv.reader(File)

    for row in lines:
            if int(row[2]) == 3:

                ef3.append([int(row[0]), row[1], int(float(row[3])), int(row[5])])
            
            if int(row[2]) == 7:
                ef7.append([int(row[0]), row[1], int(float(row[3])), int(row[5])])
            
            if int(row[2]) == 15:
                ef15.append([int(row[0]), row[1], int(float(row[3])), int(row[5])])

    df3 = pd.DataFrame(ef3, columns=['nodes', 'mode', 'msg/bits', 'steps'])
    df3 = df3.sort_values(['nodes', 'mode'])
    print(df3)
    #temp50 = [[], []]
    #temp150 = []
    #temp300 = []
    #temp550 = []
    #for i in ef3:
    #    if i[0] == 50:
    #        temp50[0].append(i[1])
    #        temp50[1].append(i[2])
    #    if i[0] == 150:
    #        temp150.append([i[1], i[2]])
    #    if i[0] == 300:
    #        temp300.append([i[1], i[2]])
    #    if i[0] == 550:
    #        temp550.append([i[1], i[2]])
    
    steps50 = int(np.mean(df3["steps"][30:39]))
    steps150 = int(np.mean(df3["steps"]))
    steps300 = int(np.mean(df3["steps"]))
    steps550 = int(np.mean(df3["steps"]))

    plt.bar([50, 150, 300, 550], [steps50, steps150, steps300, steps550],)
    plt.show()
        