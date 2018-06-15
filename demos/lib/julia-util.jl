"""
Read file into a string, use string interpolation to replace placeholders.
"""
function read_interpolated_string(filepath)
    include_string(string('"', readstring(filepath), '"'))
end
