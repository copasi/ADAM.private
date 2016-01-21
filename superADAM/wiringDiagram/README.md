This container determines the wiring diagram of a polynomial dynamical
system model.

Input is json, of type: PolynomialDynamicalSystemSet
  or, actually, one of the following three types:
    PolynomialDynamicalSystemSet
    DiscreteDynamicalSystemSet
    BooleanDynamicalSystemSet

Output is json, of type: DirectedGraph

Generally, the input should be a single polynomial dynamical system,
but if it contains multiple polynomials per node, then only the first
one is considered.
