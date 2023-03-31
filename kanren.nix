{ pkgs ? import <nixpkgs> {} }:
let
  inherit (builtins) hasAttr isAttrs;
  var = c: { var = c; };
  isVar = c: isAttrs c && hasAttr "var" c ;
  eqVar = c1: c2: c1 == c2;
  pair = l: r: {left = l; right = r;};
  isPair = u: isAttrs u && hasAttr "left" u && hasAttr "right" u;
  walk = { u, s }@args:
    let
      assv = { u, s }: pkgs.lib.lists.findFirst (x: isPair x && x.left == u) false s;
      maybePair = assv args;
    in
      if isVar u && maybePair != false then
        walk { inherit s; u = maybePair.right;}
      else
        u;
  occurs = {x, u, s}:
    if isVar u then
      x == u
    else if isPair u then
      (occurs {
        inherit x s;
        u = (walk { inherit s; u = u.left;});})
      || (occurs {
        inherit x s;
        u = (walk { inherit s; u = u.right;});})
    else
      false;
  extendSubst = {x, u, s}@subst:
    if !(occurs subst) then
      [(pair x u)] ++ s
    else
      false;
  unify = { u, v, s }:
    if u == v then
      s
    else if isVar u then
      extendSubst { x=u; u=v; s=s;}
    else if isVar v then
      unify { u=v; v=u; s=s; }
    else if isPair u && isPair v then
      let
        bigS = unify {
          u = (walk { u = u.left; s=s; });
          v = (walk { u = v.left; s = s;});
          s = s; };
      in
        if bigS == false then
          bigS
        else
          unify {
            u = (walk { u = u.right; s = bigS; });
            v = (walk { u = v.right; s = bigS; });
            s = bigS; }
    else
      false;
  equalo = { u, v }: s:
    let
      bigS = unify {
        u = (walk { u = u; s = s; });
        v = (walk { u = v; s = s; });
        s = s; };
    in
      if bigS != false then
        [ bigS ]
      else
        [];
in
  { inherit var isVar eqVar walk pair isPair occurs extendSubst unify equalo; }
