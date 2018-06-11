# translate * rotation * scale

function translate(translation)
    [1 0 0 translation[1]
     0 1 0 translation[2]
     0 0 1 translation[3]
     0 0 0 1]
end

function scale(scale)
    [scale[1] 0 0 0
     0 scale[2] 0 0
     0 0 scale[3] 0
     0 0 0 1]
end

# function rotateAboutAxis(transform, angle, axis)
#     rotation = [1 0 0 ;
#                 ]
#     rotation * transform
# end
