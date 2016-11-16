I=imread('test_noisy.png');
I=im2double(rgb2gray(I));
[m,n]=size(I);



figure,
subplot(1,2,1);
imshow(I)
I=conv2(I,fspecial('gaussian',3,1),'same');
subplot(1,2,2); imshow(I)

%% FDOG
[x,y,I_fdog_5,o]=frac_der(I,0.5);
%figure, imshow(I_fdog_5)

ori=featureorient(I, 1, 0.5, 0, ...
                                 0,0,0.5);

% maxima=max(max(I_fdog_5));
% 
% for i=1:m
% for j=1:n
%     if I_fdog_5(i,j)>0.2*maxima
%         I_fdog_5(i,j)=1;
%     else I_fdog_5(i,j)=0;
%     end
% end
% end

                             
[I_fdog_5_nm,location]=nonmaxsup(I_fdog_5,ori,1.2);
I_fdog_5_nm=mat2gray(I_fdog_5_nm);

%I_fdog_5_nm=hysthresh(I_fdog_5_nm,0.2,0.3);
figure,
subplot(1,2,2); imagesc(1.5.*I_fdog_5_nm);colormap('gray')



%% DOF
[I_dog,o]=mygradient(I,1);
%figure, imshow(I_dog)
ori=featureorient(I, 1, 0.5, 0, ...
                                 0,1,1);


[I_dog_nm,location]=nonmaxsup(I_dog,ori,1.2);
I_dog_nm=mat2gray(I_dog_nm);

%I_dog_nm=hysthresh(I_dog_nm,0.2,0.3);

subplot(1,2,1); imagesc(1.5.*I_dog_nm);colormap('gray')


%% Benchmark
% ori=featureorient(boundary, 1, 0.5, 0, ...
%                                  0,1,1);
% 
% [boundary_nm,location]=nonmaxsup(boundary,ori,1.2);
% boundary_nm=mat2gray(boundary_nm);
% subplot(1,3,2);imshow(boundary_nm)