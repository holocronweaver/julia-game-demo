"""
Read file into a string, use string interpolation to replace placeholders.
"""
function read_interpolated_string(filepath)
    include_string(string('"', readstring(filepath), '"'))
end

#TODO: Tide over until Nothing of Julia v0.7.
# Search for nullable in:
# https://github.com/JuliaLang/julia/blob/master/NEWS.md
struct Null
end

# Use object isa Null or object === null to check.
null = Null()

Nullable{T} = Union{T, Null}
