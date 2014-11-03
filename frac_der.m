function [DX,DY, mag,ori ] = frac_der( I,v )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

v1=-v/1;
v2=v1*(v1+1)/2;
v3=v2*(v1+2)/3;
v4=v3*(v1+3)/4;

dx=[v4,v3,v2,v1,0,-v1,-v2,-v3,-v4];
dy=dx';

DX=conv2(I,dx,'same');
DY=conv2(I,dy,'same');

mag = hypot(DX,DY);
ori = atan2(DY,DX);

end
