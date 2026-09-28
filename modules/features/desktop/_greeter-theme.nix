# NOT a flake-parts module: import-tree's default filter is
# `andNot (hasInfix "/_") (hasSuffix ".nix")`, so anything with a `_` path
# component is skipped. That is what lets this be a plain `import`-ed attrset
# shared between a nixosModule (sddm.nix) and a homeModule's package (_lock.nix).
#
# The greeter and the lockscreen run the same Sigil theme, so they must read the
# same settings -- this is the one copy of them. Laid over the theme's
# figure.json5 by the same names; every key is in the sigil-sddm input's
# docs/figure.md. Empty means Sigil's own look (gold #FBB929 on #0E0D0C).
{
}
