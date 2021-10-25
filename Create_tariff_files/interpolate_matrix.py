import pandas as pd
import numpy as np
from scipy.interpolate import interp1d

dir2 = 'C:/Users/w47147/misc_code/RODeO-master/RODeO-master/Create_tariff_files/Data_files/'
dir1 = dir2 + "CSV_data/"

dataframe = pd.read_excel(dir1 + "GAMS_renewables.xlsx", skiprows = 1, sheet_name = 'Sheet1')
dataframe_energy_sales = pd.read_excel(dir1 + "GAMS_Energy_Sale.xlsx", skiprows = 1, sheet_name = 'Sheet1')

interval_length = 4
year_length = 8760

def interpolate_matrix(dataframe, year_length, interval_length, interpolation_type):
	GAMS_num_rows = dataframe.shape[0]
	output_df = pd.DataFrame()
	
	# pre-check dataframe is already of desired row length; if yes simply return dataframe
	if GAMS_num_rows == year_length * interval_length:
		return dataframe
	
	if interpolation_type == "linear":
		# The ' + 1' is due to np.linspace including both upper and lower bounds in count of bins; 
		lower_inter_bound = min(dataframe["Interval"])
		upper_inter_bound = max(dataframe["Interval"])
		interpolate_hour_array = [round(x, 2) for x in np.linspace(lower_inter_bound, upper_inter_bound,  GAMS_num_rows * interval_length + 1)]
		output_df["Interval"] = interpolate_hour_array

		# Create linear interpolation function. Add column to output data frame
		for column in dataframe.columns:
			if column not in ["Date", "Interval"]:
				f = interp1d(dataframe["Interval"], dataframe[column]/max(dataframe[column]),kind = 'linear')
				output_df[column] = f(interpolate_hour_array)
		
	
	if interpolation_type == "repeat":
		# iterate through all dataframe columns and repeat 'interval_length' times
		for x in dataframe.columns:
			output_df[x] = dataframe[x].repeat(interval_length)
		
	return output_df
		
		
	

# print(interpolate_matrix(dataframe_energy_sales, year_length, interval_length, "repeat").loc[0:1])