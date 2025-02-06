import matplotlib.pyplot as plt
import csv
import  numpy as np
import pandas as pd

df = pd.DataFrame()


def third():

    with open('fire-forest_programm2 experiment-table.csv', 'r') as File:  
        lines = csv.reader(File)

        df = pd.read_csv(File)
        df = df[["density", "wind-intensity" , "(burned-trees / initial-trees) * 100"]]

    medians = df.groupby(["density", "wind-intensity"])["(burned-trees / initial-trees) * 100"].median()

    print(medians)

    plt.plot([1, 2, 3], medians[25].tolist(), label= "Density: 25%")
    plt.plot([1, 2, 3], medians[30].tolist(), label= "Density: 30%")

    plt.legend()
    # Add labels and title
    plt.xlabel('wind intensity')
    plt.ylabel('% of trees burnt')
    plt.title('Moore neighbourhood')
    # Show the plot
    plt.show()


def slow():

    with open('fire-forest_programm2 slow-table.csv', 'r') as File:  
        lines = csv.reader(File)

        df = pd.read_csv(File)

    medians = df.groupby(["slow-burning-trees", "q"])[df.columns[2]].median()

    print(medians[30].tolist())

    # Plot the bar graph
    plt.plot([70, 75, 80, 85, 90],medians[30].tolist(), label= "Slow burning trees: 30%")
    plt.plot([70, 75, 80, 85, 90],medians[45].tolist(), label= "Slow burning trees: 45%")
    plt.plot([70, 75, 80, 85, 90],medians[60].tolist(), label= "Slow burning trees: 60%")
    plt.plot([70, 75, 80, 85, 90],medians[75].tolist(), label= "Slow burning trees: 75%")

    plt.legend()
    # Add labels and title
    plt.xlabel('q (probability to spread fire)')
    plt.ylabel('% of trees burnt')
    plt.title('65% density forest, Von-Neuman neighbourhood')    
    # Show the plot
    plt.show()

slow()