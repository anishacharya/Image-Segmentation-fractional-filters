


function [im, location] = nonmaxsup(inimage, orient, radius)

if any(size(inimage) ~= size(orient))
  error('image and orientation image are of different sizes');
end

if radius < 1
  error('radius must be >= 1');
end

Octave = exist('OCTAVE_VERSION', 'builtin') == 5; % Are we running under Octave

[rows,cols] = size(inimage);
im = zeros(rows,cols);        % Preallocate memory for output image

if nargout == 2
    location = zeros(rows,cols);
end

iradius = ceil(radius);

% Precalculate x and y offsets relative to centre pixel for each orientation angle 

angle = [0:180].*pi/180;    % Array of angles in 1 degree increments (but in radians).
xoff = radius*cos(angle);   % x and y offset of points at specified radius and angle
yoff = radius*sin(angle);   % from each reference position.

hfrac = xoff - floor(xoff); % Fractional offset of xoff relative to integer location
vfrac = yoff - floor(yoff); % Fractional offset of yoff relative to integer location

orient = fix(orient)+1;     % Orientations start at 0 degrees but arrays start
                            % with index 1.

% Now run through the image interpolating grey values on each side
% of the centre pixel to be used for the non-maximal suppression.

for row = (iradius+1):(rows - iradius)
  for col = (iradius+1):(cols - iradius) 

    or = orient(row,col);   % Index into precomputed arrays
    x = col + xoff(or);     % x, y location on one side of the point in question
    y = row - yoff(or);

    fx = floor(x);          % Get integer pixel locations that surround location x,y
    cx = ceil(x);
    fy = floor(y);
    cy = ceil(y);
    tl = inimage(fy,fx);    % Value at top left integer pixel location.
    tr = inimage(fy,cx);    % top right
    bl = inimage(cy,fx);    % bottom left
    br = inimage(cy,cx);    % bottom right

    upperavg = tl + hfrac(or) * (tr - tl);  % Now use bilinear interpolation to
    loweravg = bl + hfrac(or) * (br - bl);  % estimate value at x,y
    v1 = upperavg + vfrac(or) * (loweravg - upperavg);

  if inimage(row, col) > v1 % We need to check the value on the other side...

    x = col - xoff(or);     % x, y location on the `other side' of the point in question
    y = row + yoff(or);

    fx = floor(x);
    cx = ceil(x);
    fy = floor(y);
    cy = ceil(y);
    tl = inimage(fy,fx);    % Value at top left integer pixel location.
    tr = inimage(fy,cx);    % top right
    bl = inimage(cy,fx);    % bottom left
    br = inimage(cy,cx);    % bottom right
    upperavg = tl + hfrac(or) * (tr - tl);
    loweravg = bl + hfrac(or) * (br - bl);
    v2 = upperavg + vfrac(or) * (loweravg - upperavg);

    if inimage(row,col) > v2            % This is a local maximum.
      im(row, col) = inimage(row, col); % Record value in the output
                                        % image.

      % Code for sub-pixel localization if it was requested
      if nargout == 2
        % Solve for coefficients of parabola that passes through 
        % [-1, v1]  [0, inimage] and [1, v2]. 
        % v = a*r^2 + b*r + c
        c = inimage(row,col);
        a = (v1 + v2)/2 - c;
        b = a + c - v1;
        
        % location where maxima of fitted parabola occurs
        r = -b/(2*a);
        location(row,col) = complex(row + r*yoff(or), col - r*xoff(or));
      end
      
    end

   end
  end
end


% Finally thin the 'nonmaximally suppressed' image by pointwise
% multiplying itself with a morphological skeletonization of itself.
%
% I know it is oxymoronic to thin a nonmaximally supressed image but 
% fixes the multiple adjacent peaks that can arise from using a radius
% value > 1.

if Octave
    skel = bwmorph(im>0,'thin',Inf);   % Octave's 'thin' seems to produce better results.
else
    skel = bwmorph(im>0,'skel',Inf);
end
im = im.*skel;
if nargout == 2
    location = location.*skel;
end