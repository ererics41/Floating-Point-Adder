# Floating-Point-Adder
A program that adds two 32-bit IEEE 754 floating point numbers written in MIPs assembly language.

The function MYADD takes in two floating point numbers in $a0 and $a1 and returns the sum in $v0. The adder allows 
for normalized inputs, and zero. A sample main function has been included for testing purposes. Rounding is done using
R and S bits. 
