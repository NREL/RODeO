import pandas as pd
import numpy as np
from scipy.interpolate import interp1d
import sys
sys.path.append('..')
from Create_tariff_files.interpolate_matrix import *


def interpolate_linear():
	dataframe_energy_sales = pd.read_excel("GAMS_renewables.xlsx", skiprows = 1, sheet_name = 'Sheet1')

	return interpolate_matrix(dataframe, year_length, interval_length, "linear").loc[20:40]


def test_interpolate_linear():
	input_df = interpolate_linear().round(3)
	print(input_df)
	test_df = pd.read_csv("interpolate_linear_testoutput_1.csv", index_col = 0).round(3)
	for column in input_df:
		assert input_df[column].to_list() == test_df[column].to_list()
		





def interpolate_repeat():
	dataframe_energy_sales = pd.read_excel("GAMS_Energy_Sale.xlsx", skiprows = 1, sheet_name = 'Sheet1')

	return interpolate_matrix(dataframe, year_length, interval_length, "repeat").loc[0:40]


def test_interpolate_repeat():
	input_df = interpolate_repeat().round(3)
	test_df = pd.read_csv("interpolate_repeat_testoutput_1.csv", index_col = 0).round(3)
	for column in input_df:
		if column == "Date":
			continue
		assert input_df[column].to_list() == test_df[column].to_list()
	
