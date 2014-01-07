using DataFrames
require("Datetime")
using Datetime

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
function standardize(x::Float64, max, min)
    (x - min) / (max - min)
end

function standardize(m::DataArray{Float64,1}, max, min)
    (m .- min) ./ (max - min)
end

@transform(reports, StandardLat => standardize(Lat, max_lat, min_lat))
@transform(reports, StandardLon => standardize(Lon, max_lon, min_lon))


# Make the End column a date
function parsedate(string::String)
    Datetime.datetime("yyyy-MM-ddTHH:mm:ss", string)
end
@vectorize_1arg String parsedate
@transform(reports, End => parsedate(End))

# Standardized minutes on a 0.0-1.0 scale, time from noon
function standardize_minutes(d::DateTime)
    total_min = (Datetime.hour(d) * 60) + Datetime.minutes(d)
    dist_to_noon = abs(720 - total_min)
    dist_to_noon / 720
end
@vectorize_1arg Any standardize_minutes
@transform(reports, StandardMin => standardize_minutes(End))

# Standardize day of week on a 0.0-1.0 scale
function standardize_day(d::DateTime)
    (Datetime.dayofweek(d) - 1) / 6
end
@vectorize_1arg Any standardize_day
@transform(reports, StandardDay => standardize_day(End))
 
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
    std_min = standardize_minutes(time)
    std_day = standardize_day(time)
    reports["Distances"] = [eucl_dist(std_lat, std_lon, std_min, std_day, lat, lon, min, day) for (lat,lon,min,day)=zip(reports["StandardLat"], reports["StandardLon"], reports["StandardMin"], reports["StandardDay"])]
    sorted = sortby(reports, "Distances")
    last(sortby(by(sorted[1:k, ["Description"]], "Description", nrow), "x1")[:1])
end
     
println(nearest(40.2821445, -76.8804254, Datetime.now(), 7))
