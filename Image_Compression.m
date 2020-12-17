%IMAGE COMPRESSION
%Provide the file name or it's path below 
im=imread('');
[L,W,C]=size(im);
figure()
imshow(im)
title('Uncompressed image')
im1=rgb2ycbcr(im);
y=im1(:,:,1);
cb=im1(:,:,2);
cr=im1(:,:,3);

%Chroma subsampling
resampler = vision.ChromaResampler('Resampling','4:4:4 to 4:2:2');
[cb_,cr_]=resampler(cb,cr);
[L2,W2]=size(cb_);


%Discrete Cosine Transform
y1=DCT(y,L,W);
cb1=DCT(cb_,L2,W2);
cr1=DCT(cr_,L2,W2);

%Quantisation 
yq=Quantisation(y1,L,W);
cbq=QC(cb1,L2,W2);
crq=QC(cr1,L2,W2);


%Zigzagscan
yz=zigzag(yq);
cbz=zigzag(cbq);
crz=zigzag(crq);


%Huffman encoding
[x,f]=diction(yz);
dict1=huffmandict(x,f);
yh=huffmanenco(yz,dict1);
[p,q]=diction(cbz);
dict2=huffmandict(p,q); 
cbh=huffmanenco(cbz,dict2);
[a,b]=diction(crz);
dict3=huffmandict(a,b);
crh=huffmanenco(crz,dict3);

%IMAGE DECOMPRESSION

%Huffman decoding
yhd=huffmandeco(yh,dict1);
cbhd=huffmandeco(cbh,dict2);
crhd=huffmandeco(crh,dict3);

%Dezigzag scan
ydz=dezigzag(yhd,L,W);
cbdz=dezigzag(cbhd,L2,W2);
crdz=dezigzag(crhd,L2,W2);


%DeQuantisation
yd=Dequantisation(ydz,L,W);
cbd=DQC(cbdz,L2,W2);
crd=DQC(crdz,L2,W2);


%Inverse DCT
yi=IDCT(yd,L,W);
cbi=IDCT(cbd,L2,W2);
cri=IDCT(crd,L2,W2);


rescaledMatrix = rescale(yi, 0, 255);
newy = uint8(rescaledMatrix);
%Chroma Upsampling 
sampler = vision.ChromaResampler('Resampling','4:2:2 to 4:4:4');
[newcb,newcr]=sampler(cbi,cri);

m(1:L,1:W,1)=newy(1:L,1:W);
m(1:L,1:W,2)=newcb(1:L,1:W);
m(1:L,1:W,3)=newcr(1:L,1:W);
new=ycbcr2rgb(m);
figure();
imshow(new)
title("Compressed image")
%Provide the path onto which the new image is stored 
imwrite(new,'')


function y1 =DCT(y,L,W)
Y=zeros(8*ceil(L/8),8*ceil(W/8));
for i=1:L
    for j=1:W
        Y(i,j)=y(i,j);
    end
end
y1=zeros(8*ceil(L/8),8*ceil(W/8));
for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        mat1=Y(const1:const1+7,const2:const2+7);
        y1(const1:const1+7,const2:const2+7)=dct2(mat1);
    end
end
end


function yqd=Quantisation(y1,L,W)
Q=[16,11,10,16,24,40,51,61;12,12,14,19,26,58,60,55;14,13,16,24,40,57,69,56;14,17,22,29,51,87,80,62;18,22,37,56,68,109,103,77;24,35,55,64,81,104,113,92;49,64,78,87,103,121,120,101;72,92,95,98,112,100,103,99];
yqd=zeros(8*ceil(L/8),8*ceil(W/8));

for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        mat1=y1(const1:const1+7,const2:const2+7);
        yqd(const1:const1+7,const2:const2+7)=round(mat1./Q);
    end
end
end


function yqd=QC(y1,L,W)
yqd=zeros(8*ceil(L/8),8*ceil(W/8));
Q=[17,18,24,47,99,99,99,99;18,21,26,66,99,99,99,99;24,26,56,99,99,99,99,99;47,66,99,99,99,99,99,99;99,99,99,99,99,99,99,99;99,99,99,99,99,99,99,99;99,99,99,99,99,99,99,99;99,99,99,99,99,99,99,99];
for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        mat1=y1(const1:const1+7,const2:const2+7);
        yqd(const1:const1+7,const2:const2+7)=round(mat1./Q);
    end
end
end


function V=zigzag(y)
[L,W]=size(y);
V=zeros(1,L*W);
c=0;
for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        X=y(const1:const1+7,const2:const2+7);
        V(c+1)=X(1,1);
        v=c+1;
        N=8;
        for k=1:2*N-1
            if k<=N
                if mod(k,2)==0
                    b=k;
                    for a=1:k
                        V(v)=X(a,b);
                        v=v+1;b=b-1;    
                    end
                else
                    a=k;
                    for b=1:k   
                        V(v)=X(a,b);
                        v=v+1;a=a-1; 
                    end
                end
            else
                if mod(k,2)==0
                    p=mod(k,N); b=N;
                    for a=p+1:N
                        V(v)=X(a,b);
                        v=v+1;b=b-1;    
                    end
                else
                    p=mod(k,N);a=N;
                    for b=p+1:N   
                        V(v)=X(a,b);
                        v=v+1;a=a-1; 
                    end
                end
            end
        end
        c=c+64;
    end
end
end

%This function returns two arrays of symbols and their probabilties
function [x,y]=diction(z)
x=[0];
y=[0];
k=1;
l=length(z);
for i=1:length(z)
    c=0;
    v=ismember(z(i),x);
    if v==0
        for j=i:length(z)
            if z(j)==z(i)
                c=c+1;

            end
        end
        x(k)=z(i);
        y(k)=c/l;
        k=k+1;
    end
end
end  
                
    
function M=dezigzag(y,L,W)
const1=1;
const2=1;
for i=1:64:length(y)
    in=y(i:i+63);
    num_rows=8;
    num_cols=8;
    tot_elem=length(in);
    out=zeros(num_rows,num_cols);
    cur_row=1;	cur_col=1;	cur_index=1;
   
    while cur_index<=tot_elem
        if cur_row==1 & mod(cur_row+cur_col,2)==0 & cur_col~=num_cols
            out(cur_row,cur_col)=in(cur_index);
            cur_col=cur_col+1;							%move right at the top
            cur_index=cur_index+1;

        elseif cur_row==num_rows & mod(cur_row+cur_col,2)~=0 & cur_col~=num_cols
            out(cur_row,cur_col)=in(cur_index);
            cur_col=cur_col+1;							%move right at the bottom
            cur_index=cur_index+1;

        elseif cur_col==1 & mod(cur_row+cur_col,2)~=0 & cur_row~=num_rows
            out(cur_row,cur_col)=in(cur_index);
            cur_row=cur_row+1;							%move down at the left
            cur_index=cur_index+1;

        elseif cur_col==num_cols & mod(cur_row+cur_col,2)==0 & cur_row~=num_rows
            out(cur_row,cur_col)=in(cur_index);
            cur_row=cur_row+1;							%move down at the right
            cur_index=cur_index+1;

        elseif cur_col~=1 & cur_row~=num_rows & mod(cur_row+cur_col,2)~=0
            out(cur_row,cur_col)=in(cur_index);
            cur_row=cur_row+1;		cur_col=cur_col-1;	%move diagonally left down
            cur_index=cur_index+1;

        elseif cur_row~=1 & cur_col~=num_cols & mod(cur_row+cur_col,2)==0
            out(cur_row,cur_col)=in(cur_index);
            cur_row=cur_row-1;		cur_col=cur_col+1;	%move diagonally right up
            cur_index=cur_index+1;

        elseif cur_index==tot_elem						%input the bottom right element
            out(cur_row,cur_col)=in(cur_index);							
            break										
        end
    end
    M(const1:const1+7,const2:const2+7)=out;
    if const2<(8*ceil(W/8)-8)
        const2=const2+8;
    else
        const1=const1+8;
        const2=1;
    end
end
end


function yqd=DQC(y1,L,W)
yqd=zeros(8*ceil(L/8),8*ceil(W/8));
Q=[17,18,24,47,99,99,99,99;18,21,26,66,99,99,99,99;24,26,56,99,99,99,99,99;47,66,99,99,99,99,99,99;99,99,99,99,99,99,99,99;99,99,99,99,99,99,99,99;99,99,99,99,99,99,99,99;99,99,99,99,99,99,99,99];
for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        mat1=y1(const1:const1+7,const2:const2+7);
        yqd(const1:const1+7,const2:const2+7)=Q.*mat1;
    end
end
end

function yqd=Dequantisation(y1,L,W)
Q=[16,11,10,16,24,40,51,61;12,12,14,19,26,58,60,55;14,13,16,24,40,57,69,56;14,17,22,29,51,87,80,62;18,22,37,56,68,109,103,77;24,35,55,64,81,104,113,92;49,64,78,87,103,121,120,101;72,92,95,98,112,100,103,99];
yqd=zeros(8*ceil(L/8),8*ceil(W/8));

for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        mat1=y1(const1:const1+7,const2:const2+7);
        yqd(const1:const1+7,const2:const2+7)=Q.*mat1;
    end
end
end


function y= IDCT(y1,L,W)
y=zeros(8*ceil(L/8),8*ceil(W/8));
for i=1:ceil(L/8)
    const1=(i-1)*8+1;
    for j=1:ceil(W/8)
        const2=(j-1)*8+1;
        mat1=y1(const1:const1+7,const2:const2+7);
        y(const1:const1+7,const2:const2+7)=idct2(mat1);
    end
end
end





