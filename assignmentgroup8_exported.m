classdef assignmentgroup8_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                       matlab.ui.Figure
        NoteHeightVelocityandAnglecanacceptmultiplevaluesLabel  matlab.ui.control.Label
        MaxHeightCheckBox              matlab.ui.control.CheckBox
        LoadDataButton                 matlab.ui.control.Button
        LineColourDropDown             matlab.ui.control.DropDown
        LineColourDropDownLabel        matlab.ui.control.Label
        MajorGridCheckBox              matlab.ui.control.CheckBox
        MinorGridCheckBox              matlab.ui.control.CheckBox
        ObstacleColourDropDown         matlab.ui.control.DropDown
        ObstacleColourLabel            matlab.ui.control.Label
        LineWidthSpinner               matlab.ui.control.Spinner
        LineWidthSpinnerLabel          matlab.ui.control.Label
        SpeedLabel                     matlab.ui.control.Label
        SpeedKnob                      matlab.ui.control.DiscreteKnob
        MarkerDropDown                 matlab.ui.control.DropDown
        MarkerDropDownLabel            matlab.ui.control.Label
        ChosenProjectileDropDown       matlab.ui.control.DropDown
        ChosenProjectileDropDownLabel  matlab.ui.control.Label
        Gravity                        matlab.ui.control.NumericEditField
        GravityEditFieldLabel          matlab.ui.control.Label
        angle                          matlab.ui.control.EditField
        initialvelocity                matlab.ui.control.EditField
        initialvelocityv0Label         matlab.ui.control.Label
        AngleTLabel                    matlab.ui.control.Label
        initialheight                  matlab.ui.control.EditField
        InitialHeighty0Label           matlab.ui.control.Label
        Height                         matlab.ui.control.NumericEditField
        HeighthLabel                   matlab.ui.control.Label
        Width                          matlab.ui.control.NumericEditField
        WidthwLabel                    matlab.ui.control.Label
        Length                         matlab.ui.control.NumericEditField
        LengthFromOriginlLabel         matlab.ui.control.Label
        PauseButton                    matlab.ui.control.StateButton
        AngleRangeLabel                matlab.ui.control.Label
        VelocityRangeLabel             matlab.ui.control.Label
        ChangecharacteristicsofoneprojectileLabel  matlab.ui.control.Label
        SaveDataButton                 matlab.ui.control.Button
        UITable                        matlab.ui.control.Table
        STARTButton                    matlab.ui.control.Button
        ObstaclepropertiesLabel        matlab.ui.control.Label
        ProjectilepropertiesLabel      matlab.ui.control.Label
        UIAxes                         matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        marker;  %marker of one projectile
        ChosenProjectile;
        errorState; %will error if =1
        pauseValue = 0; %pause plot if=1
        speedValue = 2; %controls speed of plot
        obs; %saves color value if obstacle is not created yet
        Lwidth = 1;
        rec; %handle for obstacle
        PlotRunning; %is 1 if plot is running else 0
        Lcolor ='k';
        checkboxValue = 1; 
    end

    methods (Access = private)
        function [v0, y0 ,T, g, w, h, l]=getParameters(app)
            %projectile parameters
            v0 = str2num(app.initialvelocity.Value);
            y0 = str2num(app.initialheight.Value);
            T = str2num(app.angle.Value);
            g = app.Gravity.Value;

            % Obstacle parameters
            w = app.Width.Value;
            h = app.Height.Value;
            l = app.Length.Value;
        end

        function errorChecking(app,isPlotting) 
            if nargin<2
                isPlotting=0;
            end
            set(app.SaveDataButton,'Enable','off'); %disable this button since this function is called when user changes the input
            %before plot is used so certain error checking only starts right before the user clicks the start plotting button
            [v0, y0 ,T, ~, ~, ~, ~]=getParameters(app);
             s="";
             app.errorState=0;
             if isempty(v0)||isempty(y0)||isempty(T)  
                 if isPlotting==1
                  s=s+"Values must be nonempty numeric values";
                  app.errorState=1;
                 end
             end
             if length(v0)~=length(y0)||length(v0)~=length(T)||length(y0)~=length(T)
                 if isPlotting==1
                 s=s+newline+"Initial velocity, initial height and angle should have the same amount of numbers";
                 app.errorState=1;
                 end
             end
             if any(T>90) || any(T<-90)
                s=s+newline+"Angle should be betweeen -90 and 90";
                app.errorState=1;
             end
                
             if any(v0<0)
                s=s+newline+"Velocity must be postive";
                app.errorState=1;
             end
             if any(y0<0)
                s=s+newline+"Initial height must be positive";
                app.errorState=1;
             end
              %other input values are autocorrected with numeric edit field(can set limits of 0 to inf)      
           
             if app.errorState==1
                 errordlg(s,'Error')
             else
                 app.errorState=0;
             end
        end

        function Calculate_and_Animate(app)
            [v0, y0 ,T, g, w, h, l]=getParameters(app); %function to get all necessary parameters
            nop = length(v0); %number of plots
            intv = 75; %number of interval used for each array
            LabelArr=tableLabel(app,nop); %adds appropriate amount of row labels


            %create arrays for multiple lines the rest needs to change size
            %to work
            tFinal=1:nop;
            %define color map for animated line
            cmp=jet(nop);


            for k = 1:nop
                % calculate t value when the animation of projectile stops
                [tempResult,temptFinal] = tFinalCalc(app,y0(k),T(k),v0(k),g,l,w,h) ;
                result(k)=string(tempResult);
                tFinal(k)=temptFinal;
            end
            tRealTime=zeros(nop,intv);
            y = zeros(nop,intv);
            x = zeros(nop,intv);
            maxY = [];
            maxX = [];
            for m = 1:nop
                tf = linspace(0,tFinal(m),round(tFinal(m)/max(tFinal)*intv)); %control linespace of each line
                tRealTime(m,1:length(tf))=tf;
                y(m,1:length(tf)) = y0(m) + (v0(m).*sind(T(m)).*tf) - ((g.*(tf.^2))./2);
                x(m,1:length(tf)) = v0(m).*cosd(T(m)).*tf;
                [a,i] = max(y(m,:)); %max y for each projectile
                maxY = [maxY,a];
                maxX = [maxX,x(m,i)];
            end

            %Obstacle
            app.rec=rectangle(app.UIAxes,'Position',[l,0,w,h],'FaceColor',app.obs);
            hold(app.UIAxes,"on");
            app.PlotRunning=1;


            %axis control
            xMax=max(x);
            yMax= max(y); 
            axisControl(app,xMax,yMax,l,h,w)


            %from https://www.mathworks.com/matlabcentral/answers/653508-indexing-animated-lines-from-array
            app.ChosenProjectile
            g=[];
            for i=1:nop 
                if i==app.ChosenProjectile
                    g = [g arrayfun(@(x) animatedline(app.UIAxes,'Marker',app.marker,'LineWidth',app.Lwidth,'color',app.Lcolor),i)];

                else
                    g = [g arrayfun(@(x) animatedline(app.UIAxes,'color',cmp(x,:)),i)];
                end
            end
            f = animatedline(app.UIAxes,'Marker','o','Color','g');
            

            leg=legend(app.UIAxes,LabelArr) ;
            leg.AutoUpdate="off"; 
            
            app.pauseValue = 0; % Set initial state to playing
            for i = 1:intv
                for k = 1:nop
                    if i <= round(tFinal(k)/max(tFinal)*intv)
                        % set the tolerance
                        tol = 1e-4;
                        if abs(y(k,i)) < tol
                            y(k,i) = 0;
                        end
                        RealTimeData(app,x(k,i),y(k,i),tRealTime(k,i),T(k),k)

                        addpoints(g(k), x(k,i), y(k,i));
                        % if y(k,i)
                        %     addpoints(f, x(k,i), y(k,i), 'o', 'Color', 'g');
                        % end

                    end
                end
                drawnow limitrate;
                pause(0.00000000000000000001);
                %for speed control
                if app.speedValue == 1
                    pause(0.3)
                elseif app.speedValue == 2
                    pause(0.025)
                end
                if app.pauseValue== 1  %pausing the axes
                    while app.pauseValue == 1
                        pause(0.1);
                    end
                else
                    pause(0.01);
                end

                if i == intv
                    for k=1:nop
                        app.UITable.Data(k,5)=result(k); %write out results in the last column of table
                    end
                end
            end
            %Plotting the max y for each projectile
            if app.checkboxValue == 1
                stem(app.UIAxes,maxX,maxY,'--','Color','r')
                for m = 1:nop
                    % Display x and y values as text annotations
                    text(app.UIAxes,maxX(m), maxY(m), ...
                        sprintf('Max Height = %.2fm', maxY(m)), ...
                        'color','blue', ...
                        'VerticalAlignment', 'bottom', ...
                        'HorizontalAlignment', 'center', ...
                        "FontSize",10, ...
                        'Position', [maxX(m), maxY(m) + 0.3]);
                end
                hold(app.UIAxes, 'off');
            end
        end
        
        function [result,tFinal] = tFinalCalc(~,y0,T,v0,g,l,w,h)
            x = l;
            t = x/(v0*cosd(T));
            y = y0 + v0*t*sind(T)-(1/2)*g*t^2;
            if y<0
                y = 0;
                a = g/2;
                b = -v0*sind(T);
                c = y - y0;
                tFinal = max(roots([a,b,c]));
                result='Undershoot!';
    
                %y = y0 + v0*(tFinal)*sind(T)-(1/2)*g*(tFinal)^2;
                % disp(y)
            elseif y >= 0 && y<=h
                tFinal = t;
                result='Hit the left of obstacle!';
            else
                y = h;
                a = g/2;
                b = -v0*sind(T);
                c = y - y0;
                t = max(roots([a,b,c]));
                x = v0*cosd(T)*t;

                if x>=l && x<=l+w
                    tFinal = t;
                    result='Hit the top of obstacle!';
                else
                    y = 0;
                    a = g/2;
                    b = -v0*sind(T);
                    c = y - y0;
                    tFinal = (max(roots([a,b,c])));
                    if T == 90
                        result = 'Undershoot!';
                    else
                        result ='Overshoot!';
                    end
                end
            end
        end

        function  axisControl(app,x,y,l,h,w)
                axis(app.UIAxes,[0 max(max(1.1*x),1.1*(l+w)) 0 max(max(1.1*y),1.1*h)]);
        end

        function    RealTimeData(app,x,y,t,T,k)
            x=sprintf("%4.2f",x);
            y=sprintf("%4.2f",y);
            t=sprintf("%4.2f",t);
        
            line1RealTime=[x y t T]';
            app.UITable.Data(k,1:4)=line1RealTime;

        end

        function LabelArr=tableLabel(app,nop)
            % LabelArr={sprinf("Line %g"),1:nop}
            LabelArr=[];
            for i=1:nop
                s=sprintf("Projectile %g",i);
                LabelArr=[LabelArr s];           
            end
             
            app.UITable.RowName=LabelArr;
        end

        function ProjectileDD(app) %changes the chosen projectile dropdown
            [v0,y0,T]=getParameters(app);
            if isempty(v0)&&isempty(y0)&&isempty(T)
                return
            end
            ddprojectile=[];
            a=max([length(v0),length(y0),length(T)]);
            for i=1:a
                s=sprintf("Projectile %g",i);
                ddprojectile=[ddprojectile s];
            end
            app.ChosenProjectileDropDown.Items=ddprojectile;
        end

        function chosenColour=ColourList(~,colorValue)
             switch colorValue
                case "Black"           
                    chosenColour = 'k';
   
                case "Red"
                    chosenColour = 'r';
                case "Yellow"
                    chosenColour = 'y';
                case "Green"
                    chosenColour = 'g';
                case "Blue"
                    chosenColour = 'b';
                case "Magenta"
                    chosenColour = 'm';
                case "Cyan"
                    chosenColour= 'c';
                case "Purple"
                    chosenColour =  [0.5, 0, 0.5];
                case "Brown"
                    chosenColour = [0.647, 0.165, 0.165];
                otherwise
                    chosenColour = 'w';
             end
        end
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        %everything below is for minmax velocity and angle calculation
        function [vmin,vmax,r] = velocityCalc(~,y0,T,g,w,h,l)
            y = 0;
            x = l;
            v1 = sqrt(g*x^2/(2*cosd(T)^2*(x*tand(T) + y0 - y)));

            y = h;
            x = l;
            v2 = sqrt(g*x^2/(2*cosd(T)^2*(x*tand(T) + y0 - y)));

            y = h;
            x = l + w;
            v3 = sqrt(g*x^2/(2*cosd(T)^2*(x*tand(T) + y0 - y)));

            if all(isnan([v1,v2,v3])) %case 1
                vmin = NaN;
                vmax= NaN;
                if l == 0
                    disp('It will hit the top of obstacle at all velocities')
                    r = 1;
                else
                    disp('It is impossible to hit the obstacle');
                    r = 2;
                end

            elseif isreal(v1) && isreal(v2) && isreal(v3) % case 2
                vmin = min([vpa(v1), vpa(v2), vpa(v3)]);
                vmax = max([vpa(v1), vpa(v2), vpa(v3)]);
                % fprintf('Minimum velocity: %f\n', vmin);
                % fprintf('Maximum velocity: %f\n', vmax);
                r = 0;

            elseif isreal(v1) && ~isreal(v2) && ~isreal(v3) %case 3
                vmin = vpa(v1);
                vmax = inf;
                % fprintf('Minimum velocity: %f\n', vmin);
                % fprintf('Maximum velocity: %f\n',vmax);
                r = 0;

            elseif  isreal(v1) && isreal(v2) && ~isreal(v3) %case 4 only v3 is not real
                vmin = vpa(v1);
                vmax = inf;
                % fprintf('Minimum velocity: %f\n', vmin);
                % fprintf('Maximum velocity: %f\n',vmax);
                r = 0;
            else %case 5 no real number
                vmin = NaN;
                vmax = NaN;
                r = 2;
                disp('It is impossible to hit the obstacle')
            end
        end
        function TRange = thetaCalc(~,y0, v0, g, h,l,w)
            y = 0;
            x = l;

            a = g*x^2/(2*v0^2);
            b = -x;
            c = y - y0 + (g*x^2/(2*v0^2)); % using quadratic formula to find T at y and x
            T = atand(roots([a,b,c]));
            T1 = vpa(T);

            y = h;
            x = l;

            a = g*x^2/(2*v0^2);
            b = -x;
            c = y - y0 + (g*x^2/(2*v0^2)); % using quadratic formula to find T at y and x
            T = atand(roots([a,b,c]));
            T2 = vpa(T);

            y = h;
            x = l + w;

            a = g*x^2/(2*v0^2);
            b = -x;
            c = y - y0 + (g*x^2/(2*v0^2)); % using quadratic formula to find T at y and x
            T = atand(roots([a,b,c]));
            T3 = vpa(T);

            A = [T1,T2,T3];
            B = [T1,T2];
 
            if ~isreal(T1)&& ~isreal(T2)&& ~isreal(T3)
                TRange="Impossible to hit"+newline+"the obstacle at any angle";
            elseif ~isreal(T2) && ~isreal(T3)
                Tmax = max(T1);
                Tmin = min(T1);
                TRange = [Tmin Tmax];
            elseif ~isreal(T3)
                Tmax = max(B(1,:));
                Tmin= min(B(2,:));
                TRange=[Tmin Tmax];
            elseif isempty(T1) && isempty(T2) 
                if y0 > y
                    % T1max = max(A(1,:));
                    T1min = min(A(1,:));

                    T2max = max(A(2,:));
                    % T2min = min(A(2,:));
                    TRange=[T1min 90 -90 T2max];
                else 
                    TRange = "Projectile can only move at 90 degrees!";
                end
                
            else
                T1max = max(A(1,:));
                T1min = min(A(1,:));

                T2max = max(A(2,:));
                T2min = min(A(2,:));
                TRange=[T1min T1max T2min T2max];
            end


            % s = char(952);
            % fprintf('The range of angle for the projectile to collide is:\n')
            % fprintf('%f < %s < %f\n',T1min,s,T1max)
            % fprintf('%f < %s < %f\n',T2min,s,T2max)

        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            t = zeros(1,4);
            app.UITable.Data= [t " "]; 
            ProjectileDD(app)          
            app.ChosenProjectile=1;
            app.errorState=0;
            app.marker='none'; 
            app.PlotRunning=0;
        end

        % Button pushed function: STARTButton
        function STARTButtonPushed(app, event)
            %reset axes and table
            cla(app.UIAxes)  
            app.UITable.Data(:,1:4)= 0;
            app.UITable.Data(:,5)=" ";
            app.UITable.Data(2:end,:)=[];

            set(app.SaveDataButton,'Enable','off');
            set(app.MaxHeightCheckBox,'Enable','off')
            errorChecking(app,1)
            if app.errorState==1
                return
            end
        
            %configure the ui elements
            app.PlotRunning=0;
            app.PauseButton.Value=0;
            PauseButtonValueChanged(app, event)
            set(app.PauseButton,'Visible','on');
            ObstacleColourDropDownValueChanged(app, event)
            set(app.STARTButton,'Enable','off')
            set(app.LoadDataButton,'Enable','off');

            Calculate_and_Animate(app)
            
            set(app.SaveDataButton,'Enable','on')
            set(app.LoadDataButton,'Enable','on');
            set(app.STARTButton,'Enable','on')
            set(app.PauseButton,'Visible','off')
            set(app.MaxHeightCheckBox,'Enable','on')
       
        end

        % Value changed function: initialheight
        function initialheightValueChanged(app, event)
            set(app.VelocityRangeLabel,'Visible','off')
            set(app.AngleRangeLabel,'Visible','off')
            errorChecking(app)
            ProjectileDD(app)            
        end

        % Value changed function: initialvelocity
        function initialvelocityValueChanged(app, event)
            errorChecking(app)
            if app.errorState==1
                return
            end
            [v0, y0 ,T, g, w, h, l]=getParameters(app);
       
            if length(v0)~=1 || length(y0)~=1 || length(T)~=1
                return
            end

            set(app.VelocityRangeLabel,'Visible','on')
            set(app.AngleRangeLabel,'Visible','off')
            ProjectileDD(app)

            [vmin,vmax,r] = velocityCalc(app,y0,T,g,w,h,l);
            if r == 1
                s = sprintf('Projectile will hit the top of obstacle at all velocities');
            elseif r == 2
                s = sprintf('It is impossible to hit the obstacle');
            else
                s =sprintf("The velocity range is\n %4.5f < v0 < %4.5f",vmin,vmax);
            end
            app.VelocityRangeLabel.Text=s;
            %msgbox(s)           
        end

        % Value changed function: angle
        function angleValueChanged(app, event)
            errorChecking(app)
            if app.errorState==1
                return
            end

            [v0, y0 ,T, g, w, h, l]=getParameters(app);
            if length(v0)~=1 || length(y0)~=1 || length(T)~=1
                return
            end
            set(app.VelocityRangeLabel,'Visible','off')
            set(app.AngleRangeLabel,'Visible','on')
            ProjectileDD(app)

            TRange = thetaCalc(app,y0, v0, g, h,l,w);
            c=char(952);
            if isstring(TRange)
                s=TRange;
     
            elseif length(TRange)==2
                s=sprintf("Angle range is:\n%4.5f < %c < %4.5f",TRange(1),c,TRange(2));     
            else
                s=sprintf("The two angle ranges are\n%4.5f < %1c < %4.5f\n%4.5f< %1c <%4.5f",TRange(1),c,TRange(2),TRange(3),c,TRange(4));          
            end
            app.AngleRangeLabel.Text=s;
           % msgbox(s)
        
        end

        % Value changed function: Gravity
        function GravityValueChanged(app, event)
            errorChecking(app)
            set(app.VelocityRangeLabel,'Visible','off')
            set(app.AngleRangeLabel,'Visible','off')

        end

        % Value changed function: Width
        function WidthValueChanged(app, event)
            % value = app.Width.Value;
           set(app.VelocityRangeLabel,'Visible','off')
            set(app.AngleRangeLabel,'Visible','off')
             errorChecking(app)
        end

        % Value changed function: Height
        function HeightValueChanged(app, event)
            % value = app.Height.Value;
               set(app.VelocityRangeLabel,'Visible','off')
            set(app.AngleRangeLabel,'Visible','off')
             errorChecking(app)
        end

        % Value changed function: Length
        function LengthValueChanged(app, event)
            % value = app.Length.Value;
               set(app.VelocityRangeLabel,'Visible','off')
            set(app.AngleRangeLabel,'Visible','off')
             errorChecking(app)
        end

        % Value changed function: ObstacleColourDropDown
        function ObstacleColourDropDownValueChanged(app, event)
            colorValue = app.ObstacleColourDropDown.Value;
            chosenColour=ColourList(app,colorValue);

           
            if app.PlotRunning==1
                app.rec.FaceColor=chosenColour;
            else
                app.obs=chosenColour;
            end
        end

        % Value changed function: ChosenProjectileDropDown
        function ChosenProjectileDropDownValueChanged(app, event)
            selectedProjectile= app.ChosenProjectileDropDown.Value;
            a=length(app.ChosenProjectileDropDown.Items);
            for i=1:a
                s=sprintf("Projectile %g",i);
                if selectedProjectile==s
                    app.ChosenProjectile=i;
                end
            end
            
        end

        % Value changed function: MarkerDropDown
        function MarkerDropDownValueChanged(app, event)
            selectedMarker = app.MarkerDropDown.Value;
            switch selectedMarker
                case "Square"
                    app.marker='s';
                case "Circle"
                    app.marker='o';
                case "Plus"
                    app.marker='+';
                case "Asterisk"
                    app.marker='*';
                case "Dot"
                    app.marker='.';
                otherwise
                    app.marker='none';
            end
            
        end

        % Value changed function: LineColourDropDown
        function LineColourDropDownValueChanged(app, event)
            colorValue = app.LineColourDropDown.Value;
            chosenColour=ColourList(app,colorValue);
            app.Lcolor=chosenColour;
        end

        % Value changing function: LineWidthSpinner
        function LineWidthSpinnerValueChanging(app, event)
            changingValue = event.Value;
            app.Lwidth = changingValue;
        end

        % Value changed function: PauseButton
        function PauseButtonValueChanged(app, event)
            app.pauseValue = app.PauseButton.Value;
            if app.pauseValue == 0
                app.PauseButton.Text = 'Pause';
                app.PauseButton.BackgroundColor = [0.94 0.55 0.55];
            else 
                app.PauseButton.Text = 'Resume';
                app.PauseButton.BackgroundColor = 'green';
            end
        end

        % Value changed function: SpeedKnob
        function SpeedKnobValueChanged(app, event)
            app.speedValue = app.SpeedKnob.Value;  
        end

        % Value changed function: MajorGridCheckBox
        function MajorGridCheckBoxValueChanged(app, event)
            major = app.MajorGridCheckBox.Value;
            if major 
                app.UIAxes.XGrid = 'on';
                app.UIAxes.YGrid = 'on';
            else
                app.UIAxes.XGrid = 'off';
                app.UIAxes.YGrid = 'off';
            end
        end

        % Value changed function: MinorGridCheckBox
        function MinorGridCheckBoxValueChanged(app, event)
            minor = app.MinorGridCheckBox.Value;
            if minor
                app.UIAxes.XMinorGrid = 'on';
                app.UIAxes.YMinorGrid = 'on';
            else
                app.UIAxes.XMinorGrid = 'off';
                app.UIAxes.YMinorGrid = 'off';
            end
            
        end

        % Value changed function: MaxHeightCheckBox
        function MaxHeightCheckBoxValueChanged(app, event)
            app.checkboxValue = app.MaxHeightCheckBox.Value;          
        end

        % Button pushed function: SaveDataButton
        function SaveDataButtonPushed(app, event)
            [v0, y0 ,T, g, w, h, l]=getParameters(app);

            filename=uiputfile("*.csv"); %user can choose file name to save
            if filename==0
                return
            end
            %obtain existing data from table
            data=app.UITable.Data;
            %add input data into the array
            data=[y0' v0' data  ];

            %all projectile data, rows and columns
            columns=get(app.UITable,'columnname');
            columns=reshape(columns,[1,5]);
            columns=convertCharsToStrings(columns);
            columns=["" "Y0" "V0" columns  ] ;
            rows=get(app.UITable,'rowname');
            rows=convertCharsToStrings(rows);
            data=[columns; rows data];
            writematrix(data,filename)

            %all obstacle data
            space=["","","","","",""]; %add spaces so column count above and below is the same
            obstacledata=["" "" space;"Gravity" g space;"Obstacle Data" "" space;"width" w space;"height",h space;"length",l space];
            writematrix(obstacledata,filename,"WriteMode","append")             
        end

        % Button pushed function: LoadDataButton
        function LoadDataButtonPushed(app, event)
            filename=uigetfile("*.csv");
            if filename==0
                return
            end
            T=readtable(filename);
            %find how many rows are projectile data
            T.Var1=string(T.Var1);

            a=startsWith(T.Var1,"Projectile");
            a=nonzeros(a);
            a=length(a);
            %{} converts table data to array, if is () will still be table
            y0=T{1:a,2};
            app.initialheight.Value=num2str(reshape(y0,1,[]));
            v0=T{1:a,3};
            app.initialvelocity.Value=num2str(reshape(v0,1,[]));
            theta=T{1:a,7};
            app.angle.Value=num2str(reshape(theta,1,[]));
            g=T{a+1,2};
            app.Gravity.Value=g;
            w=T{a+3,2};
            app.Width.Value=w;
            h=T{a+4,2};
            app.Height.Value=h;
            l=T{a+5,2};
            app.Length.Value=l;        
            ProjectileDD(app) 
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1071 634];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Projectile Simulator')
            xlabel(app.UIAxes, 'X')
            ylabel(app.UIAxes, 'Y')
            zlabel(app.UIAxes, 'Z')
            app.UIAxes.FontName = 'Cambria Math';
            app.UIAxes.Position = [431 245 510 372];

            % Create ProjectilepropertiesLabel
            app.ProjectilepropertiesLabel = uilabel(app.UIFigure);
            app.ProjectilepropertiesLabel.BackgroundColor = [0.8 0.8 0.8];
            app.ProjectilepropertiesLabel.FontSize = 14;
            app.ProjectilepropertiesLabel.FontWeight = 'bold';
            app.ProjectilepropertiesLabel.FontColor = [0.149 0.149 0.149];
            app.ProjectilepropertiesLabel.Position = [98 543 141 22];
            app.ProjectilepropertiesLabel.Text = 'Projectile properties';

            % Create ObstaclepropertiesLabel
            app.ObstaclepropertiesLabel = uilabel(app.UIFigure);
            app.ObstaclepropertiesLabel.BackgroundColor = [0.8 0.8 0.8];
            app.ObstaclepropertiesLabel.FontSize = 14;
            app.ObstaclepropertiesLabel.FontWeight = 'bold';
            app.ObstaclepropertiesLabel.Position = [97 378 142 22];
            app.ObstaclepropertiesLabel.Text = 'Obstacle properties';

            % Create STARTButton
            app.STARTButton = uibutton(app.UIFigure, 'push');
            app.STARTButton.ButtonPushedFcn = createCallbackFcn(app, @STARTButtonPushed, true);
            app.STARTButton.BackgroundColor = [0.902 0.902 0.902];
            app.STARTButton.FontSize = 14;
            app.STARTButton.FontColor = [0.149 0.149 0.149];
            app.STARTButton.Position = [119 48 128 23];
            app.STARTButton.Text = 'START';

            % Create UITable
            app.UITable = uitable(app.UIFigure);
            app.UITable.ColumnName = {'X'; 'Y'; 'Time (s)'; 'Angle (θ)'; 'Result'};
            app.UITable.RowName = {'Projectile 1'};
            app.UITable.Position = [455 37 507 211];

            % Create SaveDataButton
            app.SaveDataButton = uibutton(app.UIFigure, 'push');
            app.SaveDataButton.ButtonPushedFcn = createCallbackFcn(app, @SaveDataButtonPushed, true);
            app.SaveDataButton.Enable = 'off';
            app.SaveDataButton.Position = [639 6 100 23];
            app.SaveDataButton.Text = 'Save Data';

            % Create ChangecharacteristicsofoneprojectileLabel
            app.ChangecharacteristicsofoneprojectileLabel = uilabel(app.UIFigure);
            app.ChangecharacteristicsofoneprojectileLabel.BackgroundColor = [0.8 0.8 0.8];
            app.ChangecharacteristicsofoneprojectileLabel.FontSize = 14;
            app.ChangecharacteristicsofoneprojectileLabel.FontWeight = 'bold';
            app.ChangecharacteristicsofoneprojectileLabel.Position = [35 225 276 22];
            app.ChangecharacteristicsofoneprojectileLabel.Text = 'Change characteristics of one projectile';

            % Create VelocityRangeLabel
            app.VelocityRangeLabel = uilabel(app.UIFigure);
            app.VelocityRangeLabel.BackgroundColor = [0.8 0.8 0.8];
            app.VelocityRangeLabel.VerticalAlignment = 'top';
            app.VelocityRangeLabel.Visible = 'off';
            app.VelocityRangeLabel.Position = [286 476 146 35];
            app.VelocityRangeLabel.Text = 'Velocity Range';

            % Create AngleRangeLabel
            app.AngleRangeLabel = uilabel(app.UIFigure);
            app.AngleRangeLabel.BackgroundColor = [0.8 0.8 0.8];
            app.AngleRangeLabel.VerticalAlignment = 'top';
            app.AngleRangeLabel.Visible = 'off';
            app.AngleRangeLabel.Position = [286 419 147 49];
            app.AngleRangeLabel.Text = 'Angle Range';

            % Create PauseButton
            app.PauseButton = uibutton(app.UIFigure, 'state');
            app.PauseButton.ValueChangedFcn = createCallbackFcn(app, @PauseButtonValueChanged, true);
            app.PauseButton.Visible = 'off';
            app.PauseButton.Text = 'Pause';
            app.PauseButton.BackgroundColor = [0.9412 0.549 0.549];
            app.PauseButton.FontWeight = 'bold';
            app.PauseButton.Position = [947 353 85 23];

            % Create LengthFromOriginlLabel
            app.LengthFromOriginlLabel = uilabel(app.UIFigure);
            app.LengthFromOriginlLabel.HorizontalAlignment = 'right';
            app.LengthFromOriginlLabel.Position = [22 291 127 23];
            app.LengthFromOriginlLabel.Text = 'Length From Origin, l';

            % Create Length
            app.Length = uieditfield(app.UIFigure, 'numeric');
            app.Length.Limits = [0.01 Inf];
            app.Length.ValueChangedFcn = createCallbackFcn(app, @LengthValueChanged, true);
            app.Length.Position = [155 291 128 23];
            app.Length.Value = 50;

            % Create WidthwLabel
            app.WidthwLabel = uilabel(app.UIFigure);
            app.WidthwLabel.HorizontalAlignment = 'right';
            app.WidthwLabel.Position = [97 347 50 22];
            app.WidthwLabel.Text = 'Width, w';

            % Create Width
            app.Width = uieditfield(app.UIFigure, 'numeric');
            app.Width.Limits = [0 Inf];
            app.Width.ValueChangedFcn = createCallbackFcn(app, @WidthValueChanged, true);
            app.Width.Position = [155 347 128 22];
            app.Width.Value = 10;

            % Create HeighthLabel
            app.HeighthLabel = uilabel(app.UIFigure);
            app.HeighthLabel.HorizontalAlignment = 'right';
            app.HeighthLabel.Position = [97 320 50 22];
            app.HeighthLabel.Text = 'Height, h';

            % Create Height
            app.Height = uieditfield(app.UIFigure, 'numeric');
            app.Height.Limits = [0 Inf];
            app.Height.ValueChangedFcn = createCallbackFcn(app, @HeightValueChanged, true);
            app.Height.Position = [155 320 128 22];
            app.Height.Value = 15;

            % Create InitialHeighty0Label
            app.InitialHeighty0Label = uilabel(app.UIFigure);
            app.InitialHeighty0Label.HorizontalAlignment = 'right';
            app.InitialHeighty0Label.Position = [36 510 112 22];
            app.InitialHeighty0Label.Text = 'Initial Height, y0';

            % Create initialheight
            app.initialheight = uieditfield(app.UIFigure, 'text');
            app.initialheight.ValueChangedFcn = createCallbackFcn(app, @initialheightValueChanged, true);
            app.initialheight.HorizontalAlignment = 'right';
            app.initialheight.Position = [156 510 127 18];
            app.initialheight.Value = '10 20';

            % Create AngleTLabel
            app.AngleTLabel = uilabel(app.UIFigure);
            app.AngleTLabel.HorizontalAlignment = 'right';
            app.AngleTLabel.Position = [97 449 50 22];
            app.AngleTLabel.Text = 'Angle, θ';

            % Create initialvelocityv0Label
            app.initialvelocityv0Label = uilabel(app.UIFigure);
            app.initialvelocityv0Label.HorizontalAlignment = 'right';
            app.initialvelocityv0Label.Position = [55 478 92 25];
            app.initialvelocityv0Label.Text = 'Initial Velocity, v0';

            % Create initialvelocity
            app.initialvelocity = uieditfield(app.UIFigure, 'text');
            app.initialvelocity.ValueChangedFcn = createCallbackFcn(app, @initialvelocityValueChanged, true);
            app.initialvelocity.HorizontalAlignment = 'right';
            app.initialvelocity.Position = [156 481 127 20];
            app.initialvelocity.Value = '25 30';

            % Create angle
            app.angle = uieditfield(app.UIFigure, 'text');
            app.angle.ValueChangedFcn = createCallbackFcn(app, @angleValueChanged, true);
            app.angle.HorizontalAlignment = 'right';
            app.angle.Position = [156 449 127 19];
            app.angle.Value = '30 20';

            % Create GravityEditFieldLabel
            app.GravityEditFieldLabel = uilabel(app.UIFigure);
            app.GravityEditFieldLabel.HorizontalAlignment = 'right';
            app.GravityEditFieldLabel.Position = [97 423 50 22];
            app.GravityEditFieldLabel.Text = 'Gravity';

            % Create Gravity
            app.Gravity = uieditfield(app.UIFigure, 'numeric');
            app.Gravity.Limits = [0 Inf];
            app.Gravity.ValueChangedFcn = createCallbackFcn(app, @GravityValueChanged, true);
            app.Gravity.Position = [155 423 127 18];
            app.Gravity.Value = 9.81;

            % Create ChosenProjectileDropDownLabel
            app.ChosenProjectileDropDownLabel = uilabel(app.UIFigure);
            app.ChosenProjectileDropDownLabel.HorizontalAlignment = 'right';
            app.ChosenProjectileDropDownLabel.Position = [37 189 112 22];
            app.ChosenProjectileDropDownLabel.Text = 'Chosen Projectile';

            % Create ChosenProjectileDropDown
            app.ChosenProjectileDropDown = uidropdown(app.UIFigure);
            app.ChosenProjectileDropDown.Items = {'Projectile 1'};
            app.ChosenProjectileDropDown.ValueChangedFcn = createCallbackFcn(app, @ChosenProjectileDropDownValueChanged, true);
            app.ChosenProjectileDropDown.Position = [156 189 128 22];
            app.ChosenProjectileDropDown.Value = 'Projectile 1';

            % Create MarkerDropDownLabel
            app.MarkerDropDownLabel = uilabel(app.UIFigure);
            app.MarkerDropDownLabel.HorizontalAlignment = 'right';
            app.MarkerDropDownLabel.Position = [98 154 50 22];
            app.MarkerDropDownLabel.Text = 'Marker';

            % Create MarkerDropDown
            app.MarkerDropDown = uidropdown(app.UIFigure);
            app.MarkerDropDown.Items = {'Square', 'Circle', 'Plus', 'Asterisk', 'Dot', 'None'};
            app.MarkerDropDown.ValueChangedFcn = createCallbackFcn(app, @MarkerDropDownValueChanged, true);
            app.MarkerDropDown.Position = [156 154 128 22];
            app.MarkerDropDown.Value = 'None';

            % Create SpeedKnob
            app.SpeedKnob = uiknob(app.UIFigure, 'discrete');
            app.SpeedKnob.Items = {'Low', 'Medium', 'High'};
            app.SpeedKnob.ItemsData = [1 2 3];
            app.SpeedKnob.ValueChangedFcn = createCallbackFcn(app, @SpeedKnobValueChanged, true);
            app.SpeedKnob.FontSize = 10;
            app.SpeedKnob.Position = [973 297 35 35];
            app.SpeedKnob.Value = 2;

            % Create SpeedLabel
            app.SpeedLabel = uilabel(app.UIFigure);
            app.SpeedLabel.FontName = 'Arial Black';
            app.SpeedLabel.FontSize = 10;
            app.SpeedLabel.Position = [972 274 39 22];
            app.SpeedLabel.Text = 'Speed';

            % Create LineWidthSpinnerLabel
            app.LineWidthSpinnerLabel = uilabel(app.UIFigure);
            app.LineWidthSpinnerLabel.HorizontalAlignment = 'right';
            app.LineWidthSpinnerLabel.Position = [55 88 95 22];
            app.LineWidthSpinnerLabel.Text = 'Line Width';

            % Create LineWidthSpinner
            app.LineWidthSpinner = uispinner(app.UIFigure);
            app.LineWidthSpinner.Step = 0.1;
            app.LineWidthSpinner.ValueChangingFcn = createCallbackFcn(app, @LineWidthSpinnerValueChanging, true);
            app.LineWidthSpinner.Limits = [1 15];
            app.LineWidthSpinner.ValueDisplayFormat = '%11.1f';
            app.LineWidthSpinner.Position = [161 88 60 22];
            app.LineWidthSpinner.Value = 1;

            % Create ObstacleColourLabel
            app.ObstacleColourLabel = uilabel(app.UIFigure);
            app.ObstacleColourLabel.HorizontalAlignment = 'right';
            app.ObstacleColourLabel.Position = [55 258 91 22];
            app.ObstacleColourLabel.Text = 'Obstacle Colour';

            % Create ObstacleColourDropDown
            app.ObstacleColourDropDown = uidropdown(app.UIFigure);
            app.ObstacleColourDropDown.Items = {'None', 'Black', 'Red', 'Yellow', 'Green', 'Blue', 'Magenta', 'Cyan', 'Purple', 'Brown'};
            app.ObstacleColourDropDown.ValueChangedFcn = createCallbackFcn(app, @ObstacleColourDropDownValueChanged, true);
            app.ObstacleColourDropDown.Position = [155 258 128 22];
            app.ObstacleColourDropDown.Value = 'None';

            % Create MinorGridCheckBox
            app.MinorGridCheckBox = uicheckbox(app.UIFigure);
            app.MinorGridCheckBox.ValueChangedFcn = createCallbackFcn(app, @MinorGridCheckBoxValueChanged, true);
            app.MinorGridCheckBox.Text = 'Minor Grid';
            app.MinorGridCheckBox.FontWeight = 'bold';
            app.MinorGridCheckBox.Position = [946 544 83 22];

            % Create MajorGridCheckBox
            app.MajorGridCheckBox = uicheckbox(app.UIFigure);
            app.MajorGridCheckBox.ValueChangedFcn = createCallbackFcn(app, @MajorGridCheckBoxValueChanged, true);
            app.MajorGridCheckBox.Text = 'Major Grid';
            app.MajorGridCheckBox.FontWeight = 'bold';
            app.MajorGridCheckBox.Position = [946 565 82 22];

            % Create LineColourDropDownLabel
            app.LineColourDropDownLabel = uilabel(app.UIFigure);
            app.LineColourDropDownLabel.HorizontalAlignment = 'right';
            app.LineColourDropDownLabel.Position = [81 122 66 22];
            app.LineColourDropDownLabel.Text = 'Line Colour';

            % Create LineColourDropDown
            app.LineColourDropDown = uidropdown(app.UIFigure);
            app.LineColourDropDown.Items = {'Black', 'Red', 'Yellow', 'Green', 'Blue', 'Magenta', 'Cyan', 'Purple', 'Brown'};
            app.LineColourDropDown.ValueChangedFcn = createCallbackFcn(app, @LineColourDropDownValueChanged, true);
            app.LineColourDropDown.Position = [156 122 128 22];
            app.LineColourDropDown.Value = 'Black';

            % Create LoadDataButton
            app.LoadDataButton = uibutton(app.UIFigure, 'push');
            app.LoadDataButton.ButtonPushedFcn = createCallbackFcn(app, @LoadDataButtonPushed, true);
            app.LoadDataButton.Position = [133 12 100 23];
            app.LoadDataButton.Text = 'Load Data';

            % Create MaxHeightCheckBox
            app.MaxHeightCheckBox = uicheckbox(app.UIFigure);
            app.MaxHeightCheckBox.ValueChangedFcn = createCallbackFcn(app, @MaxHeightCheckBoxValueChanged, true);
            app.MaxHeightCheckBox.Text = 'Max Height';
            app.MaxHeightCheckBox.FontWeight = 'bold';
            app.MaxHeightCheckBox.Position = [946 523 86 22];
            app.MaxHeightCheckBox.Value = true;

            % Create NoteHeightVelocityandAnglecanacceptmultiplevaluesLabel
            app.NoteHeightVelocityandAnglecanacceptmultiplevaluesLabel = uilabel(app.UIFigure);
            app.NoteHeightVelocityandAnglecanacceptmultiplevaluesLabel.FontWeight = 'bold';
            app.NoteHeightVelocityandAnglecanacceptmultiplevaluesLabel.Position = [36 573 370 44];
            app.NoteHeightVelocityandAnglecanacceptmultiplevaluesLabel.Text = {'Note: a. Height, Velocity and Angle can accept multiple values'; '          b. Only type 1 value each to see minimum and maximum '; '              range of angle or velocity needed to hit the obstacle'};

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = assignmentgroup8_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end