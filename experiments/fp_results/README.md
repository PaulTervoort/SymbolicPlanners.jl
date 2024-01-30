## Performance Experiments

Ensure that all dependencies are installed according to the `Project.toml` in this directory. Assuming your current directory is the top-level Git repository, this can be done using the following commands in the Pkg REPL:

```julia
pkg> activate experiments/fp_results
pkg> dev ./
pkg> instantiate -v
```
For benchmark, run [`forward-extraction-benchmark.jl`](forward-extraction-benchmark) as follow:

```
julia --project=fp_results experiments/fp_results/forward-extraction-benchmark.jl
```

Domain and problem files except tireworld are from [IPC 2000](https://github.com/potassco/pddl-instances/tree/master/ipc-2000) and [IPC 2002](https://github.com/potassco/pddl-instances/tree/master/ipc-2002), as archived by [`pddl-instances`](https://github.com/potassco/pddl-instances).
Tireworld are from [Classical domains](https://github.com/AI-Planning/classical-domains/tree/main/classical/tyreworld).


See ['fp-example.jl'](fp-example) for example on how to use the forward propagation and to run use the following.

```
julia --project=fp_results experiments/fp_results/fp-example.jl
```
