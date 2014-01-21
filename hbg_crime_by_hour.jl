using DataFrames
using Datetime
using Gadfly

# All current reports
# wget http://hbg-crime.org/reports.csv
data = readtable("reports.csv")

# Parse date strings into the hour of day (0-23)
formatter = "yyyy-MM-ddTHH:mm:ss"
function hourofday(d::String)
    Datetime.hour(Datetime.datetime(formatter, d))
end
@vectorize_1arg String hourofday
@transform(data, Hour => hourofday(End))

# Group by Neighborhood; strip unclassified reports
results = by(data, ["Neighborhood", "Hour"], nrow)
complete_cases!(results)

# Plot and draw!
p = plot(results, y="x1", x="Hour", color="Neighborhood", Guide.XLabel("Hour of Day"), Guide.YLabel("Number of Reports"), Geom.bar(position=:dodge))
draw(SVG("results.svg", 9inch, 9inch), p)
