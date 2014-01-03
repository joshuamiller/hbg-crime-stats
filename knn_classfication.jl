using DataFrames

reports = readtable("reports.csv")

# Remove start time and neighborhood, then only use
# complete cases from there
delete!(reports, ["Start", "Neighborhood"])
complete_cases!(reports)

max_lat = maximum(removeNA(reports["Lat"]))
min_lat = minimum(removeNA(reports["Lat"]))
max_lon = maximum(removeNA(reports["Lon"]))
min_lon = minimum(removeNA(reports["Lon"]))

# Using very different units between lat/lon and time;
# standardize on a 0-1 range
function standardize(x, max, min)
    (x - min) / (max - min)
end

# Seems like I should be able to do this in the transform itself,
# but it doesn't seem to work for functions with multiple args
function standardize_all(m, max, min)
    map(x -> standardize(x, max, min), m)
end

@transform(reports, StandardLat => standardize_all(Lat, max_lat, min_lat))
@transform(reports, StandardLon => standardize_all(Lon, max_lon, min_lon))

formatter = "yyyy-MM-ddTHH:mm:ss"
now = string(Datetime.now())

function standardize_minutes(str)
    datetime = Datetime.datetime(formatter, str)
    total_min = (Datetime.hour(datetime) * 60) + Datetime.minutes(datetime)
    dist_to_noon = abs(720 - total_min)
    dist_to_noon / 720
end

std_min = standardize_minutes(now)
@transform(reports, StandardMin => map(standardize_minutes, End))

function standardize_day(str)
    datetime = Datetime.datetime(formatter, str)
    (Datetime.dayofweek(datetime) - 1) / 6
end
std_day = standardize_day(now)

@transform(reports, StandardDay => map(standardize_days, End))

# Want to generalize this in terms of two vectors
function eucl_dist(lat1, lon1, min1, day1, lat2, lon2, min2, day2)
    (lat2 - lat1)^2 +
    (lon2 - lon2)^2 +
    (min2 - min1)^2 +
    (day2 - day1)^2
end

# Current location and time, k neighbors to use to choose
function nearest(lat, lon, time, k)
    std_lat = standardize(lat, max_lat, min_lat)
    std_lon = standardize(lon, max_lon, min_lon)
    std_min = standardize_minutes(string(time))
    std_day = standardize_day(string(time))
    reports["Distances"] = [eucl_dist(std_lat, std_lon, std_min, std_day, lat, lon, min, day) for (lat,lon,min,day)=zip(reports["StandardLat"], reports["StandardLon"], reports["StandardMin"], reports["StandardDay"])]
    sorted = sortby(reports, "Distances")
    by(sorted[1:k, ["Description"]], "Description", nrow)["Description"][:1]
end
    
