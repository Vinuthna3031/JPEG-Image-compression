# JPEG-Image-compression
This image compression is implemented using DCT and quantisation.
Steps inolved are-
 RGB to YCbCr conversion
 Chroma downsampling
>> Discrete Cosine Transform
>> Quantisation
>> Zigzag scan
>> Huffman encoding
>> Huffman decoding 
>> Dezigzag scan
>> Dequantisation
>> Inverse Discrete Cosine Transform
>> Chroma up sampling
>> YCbCr to RGB conversion

This particular method is giving good results in compressing bitmap images(.bmp) to .jpg images.
