newPackage(
    "MMPSurfaces",
    Version => "0.1",
    Date => "September 19, 2019",
    Authors => 
    {
	{
	    Name => "Isabel Stenger",
	    Email => "stenger@math.uni-sb.de"
	},
        {
	    Name => "Rémi Bignalet-Cazalet",
	    Email => "bignalet@dima.unige.it"
	},
        {
	    Name => "Sascha Blug",
	    Email => "blug@math.uni-sb.de"
	},
    },
    Headline => "Birational classification of smooth surfaces",
    DebuggingMode => false
)

export{
    "getGenus", 
    "irregularity", 
    "eulerNumber", 
    "intersectionNumber", 
    "invariants", 
    "dimensionOfTargetSpace",
    "adjunctionMap",
    "imageUnderAdjunctionMap", 
    "exceptLocus", 
    "kodairaDimension",
    "kodairaInvariants",
    "kodairaProbabilistic", 
    "classifyKodairaNeg",
    "classifyKodaira0", 
    "classifyKodaira1",
    "classifyKodaira2",
    "classifyKodairaExceptional"
    "classify",
    }

needsPackage "Divisor"
needsPackage "Cremona"


-- computes the geometric genus of X

getGenus = method();
getGenus (Ideal) := (X) ->
(
    if pdim (betti res X) == 2 then (
    	S := ring X;
    	resX := res X;
    	dualresX := Hom(resX, S^{-dim S})[-2];
    	(F0,F1,F2) := (dualresX_0, dualresX_1, dualresX_2);
    	return rank source basis(0,F0) - rank source basis(0,F1) + rank source basis(0,F2);
    );
    R := ring X;
    OX0 := R^1/X;
    OX := sheaf OX0;
    omegaX0 := Ext^(codim X) (OX0, R^{-dim R});
    omegaX := sheaf omegaX0;
    rank HH^0(omegaX)
)



-- computes the irregularity of X

irregularity = method();
irregularity (Ideal) := (X) ->
(
    R := ring X;
    d := degree X;
    OX0 := R^1/X;
    OX := sheaf OX0;
    rank HH^1(OX)
)



-- computes K_X^2

intersectionNumber = method();
intersectionNumber (Ideal) := (X) ->
(
    R := ring X;
    if dim ring X == 5 and dim X == 3 then (
    	d := degree X;
    	q := irregularity(X);
    	g := getGenus(X);
    	e := 1 - q + g;
    	p := dimensionOfTargetSpace(X) + q - g;
    	return lift(6*e+1/2*(d^2-5*d-10*(p-1)),ZZ)
     ) else (
	  OX0 := R^1/X;
	  OX := sheaf OX0;
	  omegaX0 := Ext^(codim X) (OX0, R^{-dim R});	
	  omegaX := sheaf omegaX0;
     	  dualSheaf := sheaf(Hom(omegaX0,OX0));
	  return euler(OX)-(dim X -1)*euler(dualSheaf)+euler(dualSheaf^**2)
     );
)



-- computes the topological euler number

eulerNumber = method();
eulerNumber (Ideal) := (X) ->
(
    if dim X != 3 then error "expected surface";
    12*(1 - irregularity(X) + getGenus(X)) - intersectionNumber(X)
)



-- computes the dimension of the ambient projective space of the image under the adjunction map

dimensionOfTargetSpace = method();
dimensionOfTargetSpace (Ideal) := (X) ->
(
    if pdim (betti res X) == 2 then(
    S := ring X;
    resX := res X;
    dualresX := Hom(resX, S^{-4})[-2];
    (F0,F1,F2) := (dualresX_0, dualresX_1, dualresX_2);
    return rank source basis(0,F0) - rank source basis(0,F1) + rank source basis(0,F2)
    );
    dim source adjunctionMap X
)



-- computes the map given by |K_X + H|

adjunctionMap = method();
adjunctionMap (Ideal) := X ->
(
    R := ring X;
    RX := R/X;
    HX0 := X + (ideal random(1,R));
    HX0 = sub(HX0,RX);
    KX := canonicalDivisor(RX, IsGraded=>true);
    HX := divisor(HX0);	 
    Div := HX+KX;
    mapToProjectiveSpace(Div)
)



-- computes the image under the adjunction map

imageUnderAdjunctionMap = method();
imageUnderAdjunctionMap (Ideal) := X ->
(
    phi := adjunctionMap X;
    ideal flatten entries mingens kernel phi
)



-- returns (irregularity(X), genus(X), dim X', deg X', dim target space)

invariants = method();
invariants (Ideal) := (X) ->
(
    if dim X != 3 then error "expected surface";
    R := ring X;
    q := irregularity(X);
    g := getGenus X;
    k := intersectionNumber X;
    p := dimensionOfTargetSpace(X) + q - g;
    e := eulerNumber X;
    (print ("Irregularity = "|toString(q)),
	print("Genus = "|toString(g)),
	print("KK^2 = "|toString(k)),
	print("Sectional genus = "|toString(p)),
	print("Topological euler number = "|toString(e)));
)



-- computes the exceptional locus of the adjunction map (works only for surfaces in P^4)

exceptLocus = method();
exceptLocus (Ideal) := (X) ->
(
    R := ring X;
    if dim R != 5 then error "expected surface in P^4";
    RX := R/X;
    H1 := sub(ideal(random(1,R))+X,RX);
    H2 := sub(ideal(random(1,R))+X,RX);
    H3 := sub(ideal(random(1,R))+X,RX);
    assert (dim (H1+H2+H3) == 0);
    phi := adjunctionMap X;
    G1 := preimage(phi, H1);
    G2 := preimage(phi, H2);
    G3 := preimage(phi, H3);
    ideal mingens (G1+G2+G3+kernel(phi))
)



-- attempt to compute the Kodaira dimension using a probabilistic method

kodairaProbabilistic = method();
kodairaProbabilistic (Ideal) := (X) ->
(
    R := ring X;
    RX := R/X;
    KX := canonicalDivisor (RX, IsGraded => true);
    test :=
    i := 1;
    d := 0;
    Degs := while (i < 6) list (d) do
    (
	phi := mapToProjectiveSpace(i*KX);
	d = dim kernel phi;
	if d == 3 then return 2;
	if d == 2 then if intersectionNumber(X) > 0 then return 2 else return (1,2);
	i = i+1;
    );
    if sum Degs == 0 
    then (
	print("Kodaira dimension is likely -1. If it is, then");
	return -1;
    )
    else (
	print("Kodaira dimension is likely 0. If it is, then");
    	return 0;
    );
)






-- attempt to compute the Kodaira dimension using invariants (only for surfaces

kodairaInvariants = method();
kodairaInvariants (Ideal) := (X) ->
(
    R := ring X;
    RX := R/X;
    g := getGenus X;
    KK := intersectionNumber X;
    if (g >= 2) and (KK > 0) then return 2;
    OX0 := R^1/X;
    OX := sheaf OX0;
    omegaX0 := Ext^(codim X) (OX0, R^{-dim R});
    omegaX := sheaf omegaX0;
    P2 := rank HH^0(omegaX^**2);
    q := rank HH^1(OX);
    if (P2 == 0) and (q == 0) then return -1;
    return -42;
)



-- computes the Kodaira dimension

kodairaDimension = method();
kodairaDimension (Ideal) := (X) ->
(
    if dim X == 3 then d0 := kodairaInvariants X else return kodairaProbabilistic X;
    if d0 == -1 or d0 == 2 then return d0;
    kodairaProbabilistic X
)




-- the following methods all try to compute the minimal model, depending on the Kodaira dimension of X

classifyKodairaNeg = method();
classifyKodairaNeg (Ideal) := (X) ->
(
    q := irregularity X;
    if q >= 1 then print ("The minimal model is a non-rational ruled surface")
    else print ("The minimal model is a rational surface");
)





classifyKodaira0 = method();
classifyKodaira0 (Ideal) := (X) ->
(
    KK := intersectionNumber X;
    q := irregularity X;
    g := getGenus X;
    if (q,g) == (0,1) then if KK != 0 then print("Surface is non minimal K3-surface") else print("Surface is a minimal K3-surface");
    if (q,g) == (2,1) then if KK != 0 then print("Surface is non minimal abelian surface") else print("Surface is a minimal abelian surface");
    if (q,g) == (0,0) then if KK != 0 then print("Surface is non minimal Enriques surface") else print("Surface is a minimal Enriques surface");
    if (q,g) == (1,0) then if KK != 0 then print("Surface is non minimal bi-elliptic surface") else print("Surface is a minimal bi-elliptic surface");
)




classifyKodaira1 = method();
classifyKodaira1 (Ideal) := (X) ->
(
    S := (ring X)/X;
    phi := adjunctionMap X;
    X' := sub(imageUnderAdjunctionMap X,source phi);
    R' := ring X';
    S' := R'/X';
    phi' := map(S,S',phi.matrix);
    if not isBirational phi' then print ("Surface = P(E), with E an indecomposable rank 2 bundle over an elliptic curve and H = 3B, where B is  a section with B^2 = 1 on the surface")
    else (
    	E := exceptLocus X;
    	if dim E == 0 then print "The surface is a proper elliptic surface containing no (-1)-lines"
	 else (
	     inpt := read "The surface is a proper elliptic surface containing (-1)-lines. Do you wish to continue the computation of the minimal model? (might take a long time) y/n: ";
	     if inpt == "y" then classifyKodaira1 X';
	     )
    );
)



classifyKodaira2 = method();
classifyKodaira2 (Ideal) := (X) ->
(
    R := ring X;
    RX := R / X;
    E := exceptLocus X;
    if dim E == 0 then print "X is a surface of general type containing no (-1)-lines" 
    else (
    	inpt := read "The surface is a surface of general type containing (-1)-lines. Do you wish to continue the computation of the minimal model? (might take a long time) y/n: ";
	if inpt == "y" then classifyKodaira2 imageUnderAdjunctionMap(X);
    );
)



classifyKodairaExceptional = method();
classifyKodairaExceptional (Ideal) := (X) ->
(
    E := exceptLocus X;
    if dim E == 0 then print "Surface contains no (-1)-lines. It is either a minimal proper elliptic surface or a non minimal surface of general type";
)




classify = method();
classify (Ideal) := (X) ->
(
    if dim X != 3 then error "expected surface";
    R := ring X;
    if dim R == 5 and degree X >52 then return classifyKodaira2 X;
    k := kodairaDimension X;
    if k == -1 then return classifyKodairaNeg X;
    if k == 0 then return classifyKodaira0 X;
    if k == 1 then return classifyKodaira1 X;
    if k == 2 then return classifyKodaira2 X;
    if k == (1,2) then classifyKodairaExceptional X;
)





end



beginDocumentation()

doc ///
Key
    
Headline
    
Usage
    
Inputs
    
Outputs
    
Description
    Text
    	
    Example
    	
SeeAlso
    
///

doc ///
Key
    
Headline
    
Usage
    
Inputs
    
Outputs
    
Description
    Text
    	
    Example
    	
SeeAlso
    
///


doc ///
Key
    
Headline
    
Usage
    
Inputs
    
Outputs
    
Description
    Text
    	
    Example
    	
SeeAlso
    
///


doc ///
Key
    
Headline
    
Usage
    
Inputs
    
Outputs
    
Description
    Text
    	
    Example
    	
SeeAlso
    
///


TEST ///


///