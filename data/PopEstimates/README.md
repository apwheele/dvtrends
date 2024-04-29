# Population Estimates for ORI's

This data is originally scraped from the FBI Data Explorer, see [this post](https://andrewpwheeler.com/2023/07/29/downloading-police-employment-trends-from-the-fbi-data-explorer/), on the methodology. This population data is self reported for agencies, and derivative of the LEOKA data files.

I then take that data and fix one weird agency (Woodburn in 2011), and then do linear interpolation to fill in any missing years. If you want the original `OfficerInfo.csv` for the scraped data, [here is a dropbox link to download](https://www.dropbox.com/scl/fi/dw682j1hpe5dmt6g3zcfo/OfficerInfo.csv?rlkey=calrvmx5w0cgx3p1bwv646c68&dl=0).

Finally if an agency is missing outside of those years reported, I impute as 0 (as these tend to be small agencies). In the subsequent R analysis any ORI's missing I will also impute as 0 values.

