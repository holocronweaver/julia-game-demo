#! /usr/bin/env julia
print("Install dependencies which help develop package? [y/n]: ")
response = readline()
if lowercase(response[1]) != 'y'
    exit()
end

dev_deps = [
    "PackageCompiler",
    "Revise",
]

for dep in dev_deps
    Pkg.add(dep)
end
