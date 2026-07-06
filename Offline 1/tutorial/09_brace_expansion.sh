#!/usr/bin/bash

echo {1..5}

echo {5..1}

echo {0..20..5}

echo {a..f}

echo file{1..5}.txt

echo {cat,dog,bird}

echo CSE_{A,B,C}{1,2}

echo {x,{a,b}}{1,2}


n=5
echo {1, $n} # Does not work
seq 1 $n
