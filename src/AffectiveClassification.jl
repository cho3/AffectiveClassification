#=
AffectiveClassification.jl
auth: Christopher Ho
date: 8/31/2016
affil: none :|
desc: main driver file for these experiments
=#

using LightXML

type AffectDatum
    text::AbstractString
    affect::Vector{Real}
    source::AbstractString
end

#"Governs loading each of the different datasets"
include("load_data.jl")

#"Taking the loaded data and preprocessing it in various ways"
include("prep_data.jl")
