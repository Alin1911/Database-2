db.movies.aggregate([
    {
        $addFields: {
            secol: { $floor: { $divide: [ { $year: "$data" }, 100 ] } }
        }
    },
    {
        $group: {
            _id: "$secol",
            numar: { $sum: { $cond: [ { $regexMatch: { input: "$titlu", regex: "B" } }, 1, 0 ] } }
        }
    }
])