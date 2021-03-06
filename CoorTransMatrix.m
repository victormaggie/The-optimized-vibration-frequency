function T= CoorTransMatrix(ie)
% Transform the local coordinate to global coordinate
% ie : the number of element
% 必须再次检测坐标变换阵是否正确
   xi=gNode(gElement(ie,2),2);
   xj=gNode(gElement(ie,3),2);
   yi=gNode(gElement(ie,2),3);
   yj=gNode(gElement(ie,3),3);
    p=sqrt((xi-xj)^2+(yi-yj)^2);
    c=(xj-xi)/p;
    s=(yj-xi)/p;
    T=[c  -s   0     0;...
          s   c   0     0; ...
          0   0   c    -s;...
          0   0    s    c;];       
      return 
    
      % 检查坐标变化矩阵