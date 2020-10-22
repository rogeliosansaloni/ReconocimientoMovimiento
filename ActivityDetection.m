function ActivityDetection
    
%%
%GROUP: PDI12
%GROUP MEMBERS: Mary Grace Adina, Albert Luna, Rogelio Sansaloni
%SOFTWARE & VERSION: MATLAB R2019b
    
%%
close all;

%Read the video sequence to be processed
[video_filename, video_pathname] = uigetfile({'*.mov'},'Choose a video sequence');

%% Write your code here:

video = VideoReader(video_filename);
numImgs = get(video, 'NumberOfFrames');

frame_inicial = 600;
i_frame = frame_inicial;
while i_frame < numImgs

    frame = read(video, i_frame);
    %para la primera iteración, i_frame = 1
    if i_frame == frame_inicial
        imshow(frame);
        %cogemos la region que el usuario quiere detectar movimiento
        [x2,y2,BW,xi2,yi2]= roipoly(frame);
        %construimos la mascara a partir del polígono definido por el
        %usuario
        BW = roipoly(x2,y2, frame, xi2, yi2);    
    end
    result = frame.*uint8(BW); 
    %pasamos la imagen con la región de interés creada, a blanco y negro
    gris=rgb2gray(result);
    %en la primera iteración no entrará en este if
    if i_frame ~= frame_inicial
        %restamos el frame gris anterior al actual, y hacemos lo mismo con
        %sus complementarios, para ver la diferencia entre el anterior
        %frame y el actual
        diferencia = (frame_antic - gris) + (imcomplement(frame_antic)-imcomplement(gris));
        
        %creamos nuestro elemento estructurador de la morfologia matemática
        %como un rectangulo
        se = strel('rectangle', [3 3]);
        %binarizamos la imagen con un umbral del 0.1
        bin = imbinarize(diferencia, 0.1);
        dilation = imdilate(bin, se);
        for i=0 < 6
            dilation = imdilate(dilation, se);
        end
                
        %Obtenemos los componentes conectados de nustra imagen binaria. En
        %este caso, el objeto que esté en movimiento
        cc = bwconncomp(dilation);
        img_final= frame;
        %dibujar los rectangulos
        for i=1:cc.NumObjects
            %convierte los indices en coordenadas
            [x, y] = ind2sub(size(frame), cc.PixelIdxList{i});
            %la función mink devuelve el valor mínimo de un array, y con
            %eso obtenemos el punto situado más arriba a la izquierda
            row = mink(x, 1);
            col = mink(y, 1);
            %la anchura y altura del objeto la obtenemos obteniendo el
            %maximo del array y restandolo por los valores más pequeños
            %calculados anteriormente
            width = maxk(x, 1) - row;
            height = maxk(y, 1) - col;
            mida = size(cc.PixelIdxList{i});
            %dibuja los peatones si el tamaño está entre 600 y 2500
            if mida(1)>600 && mida(1) < 2500
                img_final = insertShape(img_final, 'Rectangle', [col row height width], 'LineWidth',3);
                img_final = insertText(img_final, [col-10 row+width],'Pedestrian','FontSize',16,'TextColor','yellow', 'BoxOpacity', 0);
            else 
                %dibuja los coches para tamaños mayores de 2500
                if mida(1) >= 2500
                    %para ello obtenemos las tres componentes de color
                    %R,G,B y calculamos su media
                    imR = img_final(:,:,1);
                    meanR =  mean(imR(x, y), 'all');
                    imG = img_final(:,:,2);
                    meanG =  mean(imG(x, y), 'all');
                    imB = img_final(:,:,3);
                    meanB =  mean(imB(x, y), 'all');
                    %para saber el color, asignamos las medias de cada
                    %color a cada canal de color
                    color_coche = [meanR meanG meanB];
                    
                    img_final = insertShape(img_final, 'Rectangle', [col row height width], 'LineWidth',3, 'Color',color_coche);
                    img_final = insertText(img_final, [col+height-32 row+width],'Car','FontSize',16,'TextColor',color_coche, 'BoxOpacity', 0);

                end
            end
            
        end
        imshow(img_final);
    end
    frame_antic = gris;
    i_frame = i_frame + 5;
end