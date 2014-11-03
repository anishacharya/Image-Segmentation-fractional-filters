function [mag,ori] = mygradient(I,method)


% method =1 : normal Derivative
% method =2 : 5 tap derivative 


if method ==1
    dx = imfilter(I,[-1  1]);
    dy = imfilter(I,[1 -1]);
    % [ori,mag]=cart2pol(dx,dy);
    mag = hypot(dx,dy);
    ori = atan2(dy,dx);
elseif method==5
    [dx, dy]=derivative5(I, 'x', 'y');
    mag = hypot(dx,dy);
    ori = atan2(dy,dx);
    
elseif method==7
    [dx, dy]=derivative7(I, 'x', 'y');
    mag = hypot(dx,dy);
    ori = atan2(dy,dx);
end

end
