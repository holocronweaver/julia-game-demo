#! /usr/bin/env julia
print("Install dependencies needed to run package? [y/n]: ")
response = readline()
if lowercase(response[1]) != 'y'
    exit()
end

app_deps = [
    "DataStructures",
    "GLFW",
    "Images",
    "ModernGL",
    "Quaternions",
]

for dep in app_deps
    Pkg.add(dep)
end
