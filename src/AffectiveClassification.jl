#=
AffectiveClassification.jl
auth: Christopher Ho
date: 8/31/2016
affil: none :|
desc: main driver file for these experiments
=#

using LightXML # for loading ISEAR: TODO only import what i need to avoid polluting namespace
using JLD # for saving, loading, general model persistence

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
function main(;
                stop_words::Bool=true, 
                prep_method::AbstractString="bag-of-words", 
                save_file::AbstractString="data.jld", 
                prep_data::Bool=false
            )

    if prep_data
        train_raw, test_raw = load_data()

        stopwords = load_stopwords()
    
        word2ind = prep_word_vecs(train_raw; stopwords=stopwords)

        # TODO sort test_raw
        raw_alm = AffectDatum[]
        raw_hashtags = AffectDatum[]
        raw_tweets = AffectDatum[]
        raw_lexicon = AffectDatum[]
        raw_semeval = AffectDatum[]

        for dat in test_raw
            if contains(dat.source, "alm")
                push!(raw_alm, dat)
            elseif dat.source == "hashtag"
                push!(raw_hashtags, dat)
            elseif dat.source == "twitter"
                push!(raw_tweets, dat)
            elseif dat.source == "lexicon"
                push!(raw_lexicon, dat)
            elseif dat.source == "semeval"
                push!(raw_semeval, dat)
            else
                println("Error: $dat")
            end
        end

        X_train, Y_train = to_bag_of_words(train_raw, word2ind)

        X_alm, Y_alm = to_bag_of_words(raw_alm, word2ind)
        X_hashtags, Y_hashtags = to_bag_of_words(raw_hashtags, word2ind)
        X_tweets, Y_tweets = to_bag_of_words(raw_tweets, word2ind)
        X_lexicon, Y_lexicon = to_bag_of_words(raw_lexicon, word2ind)
        X_semeval, Y_semeval = to_bag_of_words(raw_semeval, word2ind)
    
        println(size(X_train))
        println(size(Y_train))

        println(size(X_alm))
        println(size(Y_alm))
        println(size(X_hashtags))
        println(size(Y_hashtags))
        println(size(X_tweets))
        println(size(Y_tweets))
        println(size(X_lexicon))
        println(size(Y_lexicon))
        println(size(X_semeval))
        println(size(Y_semeval))
        
        jldopen(save_file, "w") do file
            write(file,"X_train", X_train)
            write(file,"Y_train", Y_train)
            write(file,"X_alm", X_alm)
            write(file,"Y_alm", Y_alm)
            write(file,"X_hashtags", X_hashtags)
            write(file,"Y_hashtags", Y_hashtags)
            write(file,"X_tweets", X_tweets)
            write(file,"Y_tweets", Y_tweets)
            write(file,"X_lexicon", X_lexicon)
            write(file,"Y_lexicon", Y_lexicon)
            write(file,"X_semeval", X_semeval)
            write(file,"Y_semeval", Y_semeval)
        end
    end

    file = jldopen(save_file)

    X_train = read(file, "X_train")
    Y_train = read(file, "Y_train")
    X_alm = read(file, "X_alm")
    Y_alm = read(file, "Y_alm")
    X_hashtags = read(file, "X_hashtags")
    Y_hashtags = read(file, "Y_hashtags")
    X_tweets = read(file, "X_tweets")
    Y_tweets = read(file, "Y_tweets")
    X_lexicon = read(file, "X_lexicon")
    Y_lexicon = read(file, "Y_lexicon")
    X_semeval = read(file, "X_semeval")
    Y_semeval = read(file, "Y_semeval")
    
    close(file)


    # do stuff


end

# TODO functions for casting real valued output to classification
#       precision/recall (unless can use MLBase)
#       pearsons correlation coeffiction (not in StatsBase...)
