import os
import pandas as pd

def del_unwanted(csv_path, folder_path):
    # Loading the data csv into dataframe
    df = pd.read_csv(csv_path)
    #adding the .wav extension to each of the filename in dataframe
    allowed_files = set(df['fname'].astype(str) + ".wav")

    for file in os.listdir(folder_path):
      file_path = os.path.join(folder_path, file)
    
      # Check if it's a file and not in allowed list
      if os.path.isfile(file_path) and file not in allowed_files:
          #if it is not a file in allowed list then delete it from the folder
          os.remove(file_path)
          print(f"Deleted: {file}")

dev_csv = r"C:\MY STUFF\DAIICT\Deep Learning - IT549\ResoNET\Data\FSD50K_dev_cleaned.csv"
dev_folder = r"C:\MY STUFF\DAIICT\Deep Learning - IT549\ResoNET\Data\FSD50K.dev_audio_16k"

eval_csv = r"C:\MY STUFF\DAIICT\Deep Learning - IT549\ResoNET\Data\FSDK50_eval_cleaned.csv"
eval_folder = r"C:\MY STUFF\DAIICT\Deep Learning - IT549\ResoNET\Data\FSD50K.eval_audio_16k"

esc50_csv = r"C:\MY STUFF\DAIICT\Deep Learning - IT549\ResoNET\Data\Cleaned_ESC50.csv"
esc50_folder = r"C:\MY STUFF\DAIICT\Deep Learning - IT549\ResoNET\Data\ESC50_16000"

del_unwanted(esc50_csv, esc50_folder)
del_unwanted(dev_csv, dev_folder)
del_unwanted(eval_csv, eval_folder)