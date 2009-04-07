# from "Programming Ruby, Second Edition", p. 69

def show_regexp(a, re)
    if a =~ re
	"#{$`}<<#{$&}>>#{$'}"
    else
	"no match"
    end
end
