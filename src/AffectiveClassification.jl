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


# temporary main function -- until i have a better place forthis
function main(;stop_words::Bool=true, prep::AbstractString="bag-of-words")

    train_raw, test_raw = load_data()

    stopwords = load_stopwords()
    
    word2ind = prep_word_vecs(train_raw; stopwords=stopwords)

    X_train, Y_train = to_bag_of_words(train_raw, word2ind)

    X_test, Y_test = to_bag_of_words(test_raw, word2ind)

    println(size(X_train))
    println(size(Y_train))

    println(size(X_test))
    println(size(Y_test))


end
