# rocky_mt_models

This needs a LOT of cleanup and commenting, but I'll summarize the main steps to get this working for anyone now.

map_rayshader_setup.R - This is a script to download the data from USGS, unzip it, read the rastered data and save them as a .Rdata file.
map_zip.text - THis contains all 80 links to download the data from USGS and is used by the script above.

You'll need to adjust the paths within the setup script to match your computer.

data_coordinates.csv and data_coordinates_long.csv are two files created in the setup and are used to throughout the shiny script.

The for loop that downloads and saves all the data will take awhile.  I think it took a couple hours for me.

Within server.R you'll just need to adjust a few paths again to match your setup and you should be good to go!

