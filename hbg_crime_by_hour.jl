using DataFrames
using Datetime

data = readtable("reports.csv")

formatter = "yyyy-MM-ddTHH:mm:ss"

function eachHour(m)
    map(h -> Datetime.hour(Datetime.datetime(formatter, h)), m)
end

withHours = @transform(data, Hour => eachHour(End))

results = by(withHours, ["Neighborhood", "Hour"], nrow)

using Gadfly

p = plot(results, y="x1", x="Hour", color="Neighborhood", Guide.XLabel("Hour of Day"), Guide.YLabel("Number of Reports"), Geom.bar)

draw(D3("results.js", 9inch, 9inch), p)
