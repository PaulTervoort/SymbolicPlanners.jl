## Performance Experiments

Ensure that all dependencies are installed according to the `Project.toml` in this directory. Assuming your current directory is the top-level Git repository, this can be done using the following commands in the Pkg REPL:

```julia
pkg> activate example-ka
pkg> dev ./
pkg> instantiate -v
```
For benchmark runs, look "forward_benchmark" branch

See ['fp-example.jl'](fp-example.jl) for example on how to use the forward propagation and to run use the following.

```
julia --project=example-ka example-ka/fp-example.jl
```
