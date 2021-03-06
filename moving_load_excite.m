% 水平井段套管的激振问题
% 注意惯性距的pi忘记了！！
syms gMaterial gNode L gElement gEigValue gEigvalue

% No.1 
%基本数据的输入
fprintf( '采用Euler-Bernoulli Beam 进行求解、节点自由度为2\n' )
L=input( '系统长度(m):  ' );
Nel=input( '微元体数量：' );
E=input ( '输入材料的弹性模量(10^11pa): '   );
N=input( '输入管内流体的压力（Mpa）：   ' );
Q=input('输入排量(m^3/min)：');
B=input( '输入钻头的外径(m)：   ');
D=input( '输入套管的外径(m)： ' );
d=input( '输入套管的内径(m):     ' );
ef=input( '输入水泥浆的密度（kg/m^3):   ' );
ep=input( '输入套管的密度 (kg/m^3)：    ' );
c=input('输入水泥浆的粘性系数（mpa.s）:  ');
gTimeEnd=input('输入时间长度（s）：      ');
gDeltaT=input('输入时间步长（s）：');
Force_moving=input('输入移动载荷力的大小：');
w=input('输入激振频率（Hz）:   ');
Q=Q/60;                                                       % 单位换算
N=10^6 * N;                                                   % 单位压强换算
c=10^(-3)*c;                                                  % mpa.s 和 pa.s 的单位换算
I=pi*(D^4-d^4)/64;                                            % 转动惯量的求解             % 这里忘记了pi
A1=pi*(B^2)/4;                                                % 井眼横截面积
A2=pi*(D^2)/4;                                                % 套管外面积
A3=pi*(d^2)/4;                                                % 过流面积
Uo=Q/(A1-A2);                                                 % 环空外返速
Ui=Q/A3;                                                      % 环空内流速
E=E*10^11;
timestep=gTimeEnd/gDeltaT;                                    % 计算步长
cm=( D^2+d^2)/( D^2-d^2);                                     % 环空影响系数
ma=cm*ef*A2;
mf=ef*A3;
mp=ep*(A2-A3);
m=mf+mp+ma;

% No.2 
%微元体节点进行编号
Nnode=Nel+1;                                                  % 节点总数
node=(1:Nnode);                                               % 生成节点向量
x=0:(L/Nel):L;                                                % 对节点进行坐标编号
xx=x';                                                        % 节点x坐标
yy=zeros(Nnode,1);                                            % 节点的node
                %节点编号      节点x坐标          节点y坐标
gNode=[        node'             xx                    yy];   %节点进行编号

  %No.3微元体和节点的关系矩阵

             %微元体编号               左端节点             右端节点
gElement=[    (1:Nel)',               (1:Nel)',            (2:Nnode)'];  


  %No.4 第一边界条件条件

	       %节点号        自由度号            边界值
 gBco=[       1,            1,                  0
	          1,            2,                  0
	        Nnode,          1,                  0
		    Nnode,          2,                  0];
         
  % No.5 微元体的长度
   xi=gNode(gElement(1,2),2);
   xj=gNode(gElement(1,3),2);
   yi=gNode(gElement(1,2),3);
   yj=gNode(gElement(1,3),3);
   p=sqrt((xi-xj)^2+(yi-yj)^2);
    
   % No.6 质量矩阵和刚度矩阵
   
   % 计算微元体的质量矩阵
    me=m/420*...            
	[156*p  22*p^2  54*p  -13*p^2;...
    22*p^2 4*p^3 13*p^2  -3*p^3;...
    54*p 13*p^2 156*p    -22*p^2;...
    -13*p^2  -3*p^3  -22*p^2  4*p^3];

	%套管的微元刚度矩阵
    Kea=E*I/(p^3)*...
	[12     6*p    -12         6*p;...
    6*p   4*p^2  -6*p          2*p^2; ...
    -12    -6*p     12         -6*p;...
    6*p    2*p^2  -6*p         4*p^2];

    %由科氏力产生的微元刚度矩阵
	Keb=(N*A3+mf*Ui^2)*...
    [6/(5*p) 1/10    -6/(5*p)   1/10;...
    1/10    2*p/15   -1/10      -1/30;...
    -6/(5*p) -1/10   6/(5*p)  -1/10;...
    1/10    -1/30     -1/10      2*p/15];
	%微元的总体刚度矩阵
	ke=Kea+Keb;
    
% No7. 质量矩阵和刚度矩阵进行组装 
       gK=zeros(Nnode*2);
       gM=zeros(Nnode*2);
     %按照微元体进行装配       
   for ie=1:Nel    % Nel 表示有多少个微元
     for i=1:2
       for j=1:2
           for p=1:2
               for q=1:2
                   m=(i-1)*2+p;
                   n=(j-1)*2+q;
                   M=(gElement(ie,i)-1)*2+m;      
                   N=(gElement(ie,j)-1)*2+n;
                   gK(M,N)=gK(M,N)+ke(m,n);
                   gM(M,N)=gM(M,N)+me(m,n);
               end
           end
        end
     end
   end
       
   % No.8 采用第一边界条件进行施加边界条件 
  [bc1_number,~]=size(gBco);
    w2max = max( diag(gK)./diag(gM) ); 
    
   for ibc=1:1:bc1_number
        n = gBco(ibc, 1 );                                       %这里查找的是节点
        d = gBco(ibc, 2 );                                       %查找约束施加的自由度
        m = (n-1)*2 + d;                                         %计算约束自由度在总刚矩阵中占用的自由度
        gK(:,m) = zeros( Nnode*2, 1 );                           %列化成0
        gK(m,:) = zeros( 1, Nnode*2 );                           %行化成0
        gK(m,m) = 1;  
   end
    
   for ibc=1:1:bc1_number
        n = gBco(ibc, 1 );
        d = gBco(ibc, 2 );
        m = (n-1)*2 + d;      
        gM(:,m) = zeros( Nnode*2, 1 );
        gM(m,:) = zeros( 1, Nnode*2 ) ;
        gM(m,m) = gK(m,m)/w2max/1e10 ;         
   end
    
    for i=1:Nnode*2
           for j=i:Nnode*2
               gK(j,i) = gK(i,j);
               gM(j,i) = gM(i,j);                                  % 进行对称化矩阵
           end
    end
  
    % 计算特征值和特征想
    [gEigVector, gEigValue] = eigs(gK, gM, 3, 'SM' );      %提取三阶特征值 
    
    for ibc=1:1:bc1_number
	    n = gBco(ibc, 1 );
        d = gBco(ibc, 2 );
        m = (n-1)*2 + d;                                   
        gEigVector(m,:) = gBco(ibc,3);                  %对振型进行边界化
    end
                     
    w1=sqrt(gEigValue(1,1))/2/pi;                                    
    w2=sqrt(gEigValue(2,2))/2/pi;                     % 提取前两阶固有振动频率
    
    %No.9 水泥浆引起的微元的粘性阻尼矩阵 
    %No.9 水泥浆引起的微元的粘性阻尼矩阵 
    % 采用粘性阻尼进行求解
    dRatio=0.008;                                            % 结构阻尼比，钢材水泥选取0.008
    % Rayleigh Damping                                       % 粘性阻尼，采用比例阻尼方式
    alpha=2*(w1*w2)*dRatio/(w1+w2);                          % w1、w2是管材的固有振动频率
    beta= 2*dRatio/(w1+w2); 
    Ca=alpha*gM+beta*gK;                                     % rayleigh 方法确定的结构阻尼矩阵
    
    % 科氏阻尼矩阵
	cb=-(2*mf*Ui + ma*Uo)*...
    [0          -p/10       -1/2            p/10;...
    p/10       0           -p/10          p^2/60;...
    1/2        p/10           0            -p/10;...
    -p/10     -p^2/60       p/10              0];                                
    % 对阻尼矩阵进行组装，从而能够的出整体的阻尼矩阵
 
 Cb=zeros(Nnode*2);
    for ie=1:Nel                                                    % Nel 表示有多少个微元
     for i=1:2
       for j=1:2
           for p=1:2
               for q=1:2
                   m=(i-1)*2+p;
                   n=(j-1)*2+q;
                   M=(gElement(ie,i)-1)*2+m;      
                   N=(gElement(ie,j)-1)*2+n;
                   Cb(M,N)=Cb(M,N)+cb(m,n);
               end
           end
        end
     end
    end
   
   gC=Cb+Ca;

% gDeltaT ------ 时间步长
% gTimeEnd ----- 计算结束时刻
% gDisp -------- 位移时程响应
% gVelo -------- 速度时程响应
% gAcce -------- 加速度时程响应
%----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    % 移动载荷下的激振问题
    % 移动载荷下的响应分析应该是先判定载荷位置，在对力进行赋值，从而确定力的大小，再用Newmark方法进行计算。
    % 根据形函数、将移动载荷分解到节点等效力。
    % 对载荷位置进行初步判定
    % 移动载荷的激振问题，必须重新再看一遍。
   gDisp=zeros(gNode*2, timestep);                                  % 定义位移矩阵                  
   gVelo=zeros(gNode*2, timestep);                                  % 定义速度矩阵
   v=Q/A3;                                                          % 假设水泥浆作为驱动动力
   f=zeros(gNode*2, timestep);                                      % 定义力矩阵
    for i=1:timestep                                                % 每个时间步长计算
        cosin=mod(i*v, p)/p;
        N1=1-3*cosin^2+2*cosin^3;
        N2=(cosin-2*cosin^2+cosin^3)*p;
        N3=3*cosin^2-2*cosin^3;
        N4=(-cosin^2+cosin^3)*p;
        Hermite=[N1, N2, N3, N4]';
        N_Moving=Force_moving*Hermite;                              % 将移动载荷的力按照hermite差值进行叠加             
        Mload_node=ceil(i*v/p);
        Mload_Hermite=[              Mload_node,            1         N_Moving11;...
                                     Mload_node,            2         N_Moving21;...
                                     Mload_node +1,         1         N_Moving31;...
                                     Mload_node +1,         2         N_Moving41];
        [number_Mload_node, ~]=size(Mload_Hermite);
        for v =1: number_Mload_node
            n=Mload_Hermite(v,1);                         % 运动到的节点
            d=Mload_Hermite(v,2);                         % 运动到的自由度
            m=(n-1)*2 +d;                                 % 在总的坐标轴中占据自由度       
            f(m,i)=Mload_Hermite(v, 3);
        end
    end   
     % 这里需要重新定义没有施加边界条件的质量矩阵、刚度矩阵
    
    hK=zeros(Nnode*2);
    hM=zeros(Nnode*2);
    
   for ie=1:Nel                                              %Nel 表示有多少个微元
     for i=1:2
       for j=1:2
           for p=1:2
               for q=1:2
                   m=(i-1)*2+p;
                   n=(j-1)*2+q;
                   M=(gElement(ie,i)-1)*2+m;      
                   N=(gElement(ie,j)-1)*2+n;
                   hK(M,N)=hK(M,N)+ke(m,n);
                   hM(M,N)=hM(M,N)+me(m,n);
               end
           end
        end
     end
   end
    
   %采用振动Newmark方法进行振动分析
    gama = 0.5 ;
    beta = 0.25 ;                                                   % 采用平均加速度方法 Newmark- beta 方法，平均加速度法
    [~,N]=size(hK);
    alpha0 = 1/beta/gDeltaT^2;
    alpha1 = gama/beta/gDeltaT;
    alpha2 = 1/beta/gDeltaT;
    alpha3 = 1/2/beta - 1;
    alpha4 = gama/beta - 1;
    alpha5 = gDeltaT/2*(gama/beta-2);
    alpha6 = gDeltaT*(1-gama);
    alpha7 = gama*gDeltaT;
    K1 = hK + alpha0*hM + alpha1*gC;                        %计算有效刚度矩阵
     
% 对K1进行边界条件处理
   [bc1_number,dummy] = size(gBco) ;
   K1im = zeros(Nnode, bc1_number);
    for ibc=1:1:bc1_number
        n=gBco(ibc,1);
        d=gBco(ibc,2);
        m=(n-1)*2+d;
        K1im(:, ibc)=K1(:, m);                               %这是将原始边界条件储存到Klim中去，方便后面对力进行施加边界条件
        K1(:,m) = zeros( Nnode*2, 1 );                       %将有效刚度矩阵进行赋值
        K1(m,:) = zeros( 1, Nnode*2);                        %化行、化列法对边界条件进行施加
        K1(m,m) = 1.0;                                       %施加边界条件
    end
    [KL,KU] = lu(K1);                                        %进行LU分解，节省后面的求解时间
   
   %计算初始加速度
    gAcce(:,1) =hM\(f(:,1)-hK*gDisp(:,1)-gC*gVelo(:,1));     %初始加速度一般都设为零的      
   
   %对每一个时间步计算
    for i=2:1:timestep
        if mod(i,100) == 0
            fprintf( '当前时间步：%d\n', i );                 %显示整数步长，模为零的情况
        end
        f1 =f(:,i)+hM*(alpha0*gDisp(:,i-1)+alpha2*gVelo(:,i-1)+alpha3*gAcce(:,i-1)) ...
                  + gC*(alpha1*gDisp(:,i-1)+alpha4*gVelo(:,i-1)+alpha5*gAcce(:,i-1)) ;            
       
        % 对f1进行边界条件处理, 施加力的边界条件
        [bc1_number,dummy] = size( gBco ) ;
        for ibc=1:1:bc1_number
            n = gBco(ibc, 1 ) ;
            d = gBco(ibc, 2 ) ;
            m = (n-1)*2 + d ;
        %如果是力  那么需要对力进行施加边界条件
            f1 = f1 - gBco(ibc,3) * K1im(:,ibc) ;      % 这个是施加边界条件    采用化行化列法施加边界条件
            f1(m)=gBco(ibc,3);
        end
        y = KL\f1 ;
        gDisp(:,i) = KU\y ;
        gAcce(:,i) = alpha0*(gDisp(:,i)-gDisp(:,i-1)) - alpha2*gVelo(:,i-1) - alpha3*gAcce(:,i-1) ;   % 下一个时段的加速度
        gVelo(:,i) = gVelo(:,i-1) + alpha6*gAcce(:,i-1) + alpha7*gAcce(:,i) ;
    end
    
   % 绘制时程曲线
    t = 0:gDeltaT:(gTimeEnd-gDeltaT);
    d = gDisp((floor(Nnode/2)*2)+1,:);
    subplot(2,1,1);
    plot( t, d );
    title( 'L/4处挠度时程曲线');
    xlabel( '时间(s)');
    ylabel( '挠度(cm)' );
    grid on
   
    % 对时程曲线进行FFT变换，获取频谱特性
    fd = fft( d ) ;
    df = 1/gTimeEnd ;
    f = (0:length(d)-1)*df ;
    subplot(2,1,2);
    plot(f,abs(fd)) ;
    set(gca,'xlim',[0,10]) ;
    title( 'L/4处挠度的频谱图' ) ;
    xlabel( '频率(Hz)') ;
    ylabel( '幅值' ) ;
   
    % 标注频率峰值
    fifi1 = diff(abs(fd));
    n = length(fifi1) ;
    d1 = fifi1(1:n-1);
    d2 = fifi1(2:n) ;
    indmax = find( d1.*d2<0 & d1>0 )+1;
    for i=1:length(indmax)
        if f(indmax(i)) > 10
            break;
        end
        text( f(indmax(i)+2), abs(fd(indmax(i)))*0.9, sprintf('f=%.3f',f(indmax(i))));
    end
   


 