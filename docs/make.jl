using Documenter, Gadfly, SaunaModel

makedocs(modules=[SaunaModel],
    format=Documenter.HTML(),
    sitename="SaunaModel.jl",
    authors="Brent Halonen, Mark Halonen",
    pages=[
        "Home" => "index.md",
        "Use" => Any[
            "Guide" => "use/guide.md",
            "API" => "use/api.md"
        ],
        "Theory" => Any[
            "Overview" => "theory/overview.md",
            "Heat Transfer" => "theory/heat_transfer.md",
            "Differential Equations" => "theory/diffeq.md",
            "Human Heating" => "theory/human.md"
            ],
    ]
    )