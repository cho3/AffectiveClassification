"""
Data loading and preprocessing stuff
"""


punctuation = Set{Char}(['.', ',', '\'', '"', '!', '?'])

function load_stopwords(file::AbstractString=joinpath("..", "stopwords_en.txt"))

    f = open(file)
    stopwords = Set{AbstractString}()
    for word in readlines(f)
        push!(stopwords,strip(word,('\n', '\r', )))
    end
    close(f)

    return stopwords
end

# pass through data to figure out word->index mappings, size of vocabulary
# can also remove stop words and do stemming/word normalization here
function prep_word_vecs(data::Vector{AffectDatum}; stopwords::Set{AbstractString}=Set{AbstractString}() )
    
    word2ind = Dict{AbstractString,Int}()

    for dat in data

        text = split(dat.text, ' ')
        for word in text
            # TODO optional text normalization here (specific form of words can have different qualities as modifiers or affective)
            word_clean = lowercase( strip(word,  punctuation) )
            if (get(word2ind, word_clean, 0) != 0 ) || (word_clean in stopwords)
               continue 
            end

            idx = length(word2ind) + 1
            word2ind[word_clean] = idx

        end

    end

    return word2ind

end

function to_bag_of_words(
                        data::Vector{AffectDatum}, 
                        word2ind::Dict{AbstractString,Int}=prep_word_vecs(data) 
                        )
    
    n = length(data)
    m = length(word2ind)

    X = spzeros(m,n)
    Y = spzeros(9,n) # data is more dense than not, but its mixed

    for (i,dat) in enumerate(data)

        text = split(dat.text, ' ')
        for word in text
            # TODO text norm...
            word_clean = lowercase( strip( word, punctuation) )
            idx = get(word2ind, word_clean, -1)
            # it's a stopword
            if idx == -1
                continue
            end
            X[idx,i] += 1
        end
        
        Y[:,i] = dat.affect
    end

    return X, Y 
end


# TODO, also check if htere's an existing implementation
function tfidf()

end

# TODO, also check if existing implementation, if not, meh, LSI is easy
function lsi()

end


