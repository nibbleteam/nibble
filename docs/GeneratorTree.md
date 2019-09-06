# Generator Tree

For each generator tree `g` there is a generated tree `nom`:

g -> nom

The function `B` builds a `nom` from a given generator tree `g`:

B(x): g -> nom

# Nodes

Each of the `g` and `nom` trees are made of nodes. `g` nodes are called `gn`
and `nom` nodes are called `nomn`:

g: set(gn)
nom: set(nomn)

Each `nomn` has a direct relationshit to a `gn`, so there is a function `G`enerator
that finds a `gn` given a `nomn`:

G(x): nomn -> gn

# Updating trees

Updating trees can happens with one of the three operations described below:

1. add(a: gn, b: gn):
    
    adds b to a

2. remove(a: gn, b: gn):
    
    removes b from a

3. update(a: gn, b: gn, c: gn):
    
    finds children b of a and swaps it with c

# Minimum update

Given a `g` and a `nom` and a `g'` derived from `g` using the above rules, find the
mininum changes(`C`) needed to make `C`(`nom`) = `B`(`g'`).
