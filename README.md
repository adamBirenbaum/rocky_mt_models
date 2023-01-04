# rocky_mt_models

[(Example .gif)](https://i.imgur.com/1IKmtY2.mp4)

This needs a LOT of cleanup and commenting, but I'll summarize the main steps to get this working for anyone now.


## Step 1.  Get a list of download links to the data from USGS

The USGS national map viewer [(link)](https://viewer.nationalmap.gov/basic/) is the tool I used to get the elevation data.  Should look like the screenshot below.

![](D:/abire/Documents/rocky_mt_models/readme/USGS_viewer.png)

Use the box/point tool to drag a box over the region of interest.

![](D:/abire/Documents/rocky_mt_models/readme/region.png)

On the left side under the Data category, select Elevation Products (3DEP) and make sure ArcGrid is selected.  I've been using the 1/3 arc second products, but I believe the other categories should work too.  Some are only available in certain regions, but from my experience 1/3 arc second is available everywhere and it still has a resolution of 30 feet.

Click Find Products.  It may take a minute to load the products in the region.

Once they're loaded, you can click Show Thumbnails to ensure that the data covers the entire region (shown below).
![](D:/abire/Documents/rocky_mt_models/readme/thumbnails.png)

Then click save as Text to save the download links to a txt file.  **Rename this file map_zips.txt**


## Step 2.  Run the setup script to download and read all the data

map_rayshader_setup.R is the setup script you'll need to use.  You just need to set the path to your directory and make a data folder.  Details are given at the head of the file.

## Step 3. Change the path in the server.R file

Within server.R you'll just need to adjust the path again to match your setup and you should be good to go!

