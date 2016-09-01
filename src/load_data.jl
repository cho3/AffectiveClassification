#=

Load data into a unified format, optionally save

=#

#affect = anger,disgust,fear,joy,sadness,surprise,anticipation,trust,valence
#positive/negative = valence = (see cambria hourglass of emotions paper)
#anticipation/trust added from plutchik
affect2ind = Dict{AbstractString,Int}("anger"=>1, "disgust"=>2, "fear"=>3,
                                    "joy"=>4, "sadness"=>5, "surprise"=>6, 
                                    "anticipation"=>7, "trust"=>8, "negative"=>9,
                                    "positive"=>9)
                                    
function load_twitter(fname::AbstractString=joinpath("..","affect-data","Jan9-2012-tweets-clean.txt"))

    twitter_file = open(fname)

    twitter = AffectDatum[]
    src = "twitter"
    for line in readlines(twitter_file)
        dat = split(line,'\t')
        label = strip(dat[end], (' ', ':', '\t', '\n'))
        text = strip(join(dat[2:end-1]), (' ', '\t', '\n'))
        affect = zeros(9)
        idx = get(affect2ind,label,-1)

        # something went wrong
        if idx == -1
            print(line)
            print(label)
            print(dat)
            break
        end

        # negative = -positive = negative valence
        if (label == "negative")
            affect[idx] = -1
        else
            affect[idx] = 1
        end
        push!(twitter, AffectDatum(text, affect, src))
    end
    close(twitter_file)

    return twitter
end



function load_hashtags(fname::AbstractString=joinpath("..","affect-data","NRC-Hashtag-Emotion-Lexicon-v0.2","NRC-Hashtag-Emotion-Lexicon-v0.2.txt") )

    hashtag_data = open(fname)
    # preload all data (its organized by affect class)
    data = AbstractString[]
    start_flag = false
    for line in readlines(hashtag_data)
        # skip header
        if contains(line,"..........")
            start_flag = true
            continue
        end
        if start_flag
            push!(data,line)
        end
    end

    hashtags = Dict{AbstractString,Vector{Real}}()
    seen = Dict{AbstractString,Int}()
    for line in data
        datum = split(line,'\t')
        if length(datum) < 3
            warn("skipping line: $(repr(line))")
            continue
        end
        label = datum[1]
        # TODO clean hashtags
        hashtag = datum[2]
        val = float(datum[3])
        affects = get(hashtags, hashtag, zeros(9))
        idx = get(affect2ind, label, -1)
        if idx == -1
            print(repr(line))
            break
        end
        affects[idx] = val
        hashtags[hashtag] = affects
        seen[hashtag] = get(seen,hashtag, 0) + 1
    end

    for (hashtag, count) in seen
        assert( count <= 8 ) #otherwise its being double counted or worse
    end

    return hashtags
end


function load_lexicon(fname::AbstractString=joinpath("..","affect-data","NRC-Emotion-Lexicon-v0.92","NRC-emotion-lexicon-wordlevel-alphabetized-v0.92.txt") )

    # unfortunately, this is formated differently, so need anew function
    lexicon_file = open(fname)

    data = Dict{AbstractString,Vector{Int}}()
    src = "lexicon"
    header = 0
    for line in readlines(lexicon_file)
        if header == 2
            # should probably just be a new line
            datum = split(line, '\t')
            if length(datum) < 3
                print(datum)
                continue
            end
            word = strip(datum[1], (' ', '\t', '\n'))
            affect = strip(datum[2], (' ', '\t', '\n'))
            val = float(datum[3])
            idx = get(affect2ind, affect, -1)
            # should not happen
            if idx == -1
                error("wtf: $line")
            end
            # easier to do it this way so you don't have to explicitly keep track of what hte last word was
            affects = get(data, word, zeros(Int,9))
            # negative is -valence, positive = positive valence
            if affect == "negative"
                affects[idx] -= val
            else
                affects[idx] += val
            end
            data[word] = affects
        elseif header > 2
            warn("wtf just happened")
            break
        end
        if contains(line, ".......")
            header += 1
        end
    end

    lexicon = AffectDatum[]
    for (word, affect) in data
        push!(lexicon, AffectDatum(word, affect, src))
    end

    return lexicon
end


function load_isear(fname::AbstractString=joinpath() )

    return isear
end


codemap = Dict{Int,AbstractString}(2=>"anger-disgust", 3=>"fear", 4=>"joy", 6=>"sadness", 7=>"surprise")
function load_fairytales(path::AbstractString, src::AbstractString)
    
    files = readdir(joinpath(path,"agree-sent"))

    data = AffectDatum[]
    for file in files
        if !isfile(joinpath(path,"agree-sent",file))
            continue
        end
        in_file = open(joinpath(path,"agree-sent",file))
        for line in readlines(in_file)
            datum = split(line,'@')
            if length(datum) != 3
                print(datum)
                continue
            end
            text = strip(datum[3], ('\n', '\t', ' ', '\'', '"'))
            id = strip(datum[1], ('\n', '\t', ' '))
            affect_str = get(codemap, parse(Int, strip(datum[2], ('\n', '\t', ' '))), "null")
            if affect_str == "null"
                print(datum)
                continue
            end
            affect = zeros(9)
            if affect_str == "anger-disgust"
                affect[ affect2ind["anger"] ] = 0.5
                affect[ affect2ind["disgust"] ] = 0.5
            else
                ind = get(affect2ind, affect_str, -1)
                if ind == -1
                    print(datum)
                    continue
                end
                affect[ind] = 1
            end
            push!(data, AffectDatum(text, affect, src))
        end
        close(in_file)
    end
    return data
end

function load_alm(path::AbstractString=joinpath("..","affect-data","alm2007"))

    grimm = load_fairytales(joinpath(path,"Grimms"), "alm-Grimm")
    potter = load_fairytales(joinpath(path,"Potter"), "alm-Potter")
    andersen = load_fairytales(joinpath(path,"HCAndersen"), "alm-Andersen")


    data = vcat(grimm, potter, andersen)

    return data
end


function load_semeval(; path::AbstractString=joinpath("..","affect-data","semeval2007","AffectiveText."), suff::AbstractString="test")

    doc = parse_file(joinpath(join([path,suff], ""),join(["affectivetext_",suff,".xml"], "") ) )
    node = root(doc)
    texts = Dict{Int,AbstractString}()
    for c in child_elements(node)
        text = content(c)
        id = parse(Int,attribute(c,"id"))
        texts[id] = text
    end

    emo_file = open(joinpath(join([path,suff], ""),join(["affectivetext_",suff,".emotions.gold"], "") ) )
    affects = Dict{Int,Vector{Real}}()
    for line in readlines(emo_file)
        dat = split(line," ")
        id = parse(Int,dat[1])
        affect = [float(x)/100. for x in dat[2:end]]
        affects[id] = affect
    end
    close(emo_file)
    
    val_file = open(joinpath(join([path,suff], ""),join(["affectivetext_",suff,".valence.gold"], "") ) )
    valences = Dict{Int,Float64}()
    for line in readlines(val_file)
        dat = split(line," ")
        id = parse(Int,dat[1])
        val = float(dat[2])/100.
        valences[id] = val
    end
    close(val_file)
        
    
    data = AffectDatum[]
    src = "semeval"
    for id in keys(texts)
        valence = valences[id]
        text = texts[id]
        _affect = affects[id]
        affect = zeros(9)
        affect[1:6] = _affect
        affect[9] = valence
        push!(data, AffectDatum(text,affect,src))
    end


    return data

end

function load_data(; train_fraction::Float64=0.85, rng::AbstractRNG=RandomDevice()) # TODO default args 

    alm = load_alm()
    twitter = load_twitter()
    lexicon = load_lexicon()
    hashtags = load_hashtags()

    # shuffle data for reasons
    alm = shuffle!(rng, alm)
    twitter = shuffle!(rng, twitter)
    lexicon = shuffle!(rng, lexicon)
    hashtags = shuffle!(rng, lexicon)

    # split into test set; should do it better but whatever
    n = convert(Int, round(length(alm) * train_fraction) ) 
    alm_train, alm_test = alm[1:n], alm[n+1:end]

    n = convert(Int, round(length(twitter) * train_fraction) )
    twitter_train, twitter_test = twitter[1:n], twitter[n+1:end]

    n = convert(Int, round(length(lexicon) * train_fraction) ) 
    lexicon_train, lexicon_test = lexicon[1:n], lexicon[n+1:end]

    n = convert(Int, round(length(hashtags) * train_fraction) ) 
    hashtags_train, hashtags_test = hashtags[1:n], hashtags[n+1:end]
    semeval_train, semeval_test = load_semeval(suff="test"), load_semeval(suff="trial")

    train = vcat(alm_train, twitter_train, lexicon_train, hashtags_train, semeval_train)
    test = vcat(alm_test, twitter_test, lexicon_test, hashtags_test, semeval_test)

    # one more shuffle
    train = shuffle!(rng, train)
    test = shuffle!(rng, test)

    return train, test
end
