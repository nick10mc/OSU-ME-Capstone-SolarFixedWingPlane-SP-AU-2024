%% Lift & Drag Calculator
% Nick McCatherine
% 3/30/2024
% Version 4, 10/26/2024

clear;
close all;
clc;

% Load relevant data
% Generated through XFLR, imported into MATLAB, then resaved as .mat
Tipname = input("Tip Data Set (IE: sd7037dat.mat): ","s");
Rootname = input("Root Data Set(IE: e421dat.mat): ","s");
tipdat = load(Tipname);
rootdat = load(Rootname);
tipField = fieldnames(tipdat);
rootField = fieldnames(rootdat);
tipdat=tipdat.(tipField{1});
rootdat=rootdat.(rootField{1});
alpha1 = tipdat(:,1);
cl1 = tipdat(:,2);
cd1 = tipdat(:,3);
alpha2 = rootdat(:,1);
cl2 = rootdat(:,2);
cd2 = rootdat(:,3);

%% Set Environment parameters
density = 1.225;
dynVisc = 1.98E-5;
G=9.81;
mach = 343; % m/s

%% Set Airfoil Parameters (in m, kg, s)
rootchord = input("Input root chord length (ie: 0.3408m): "); % 0.3408
tipchord = input("Input tip chord length (m): "); 
span = input("Wing Span (ie: 2.310m): ")/2; %assuming two wings - 2.159
velocity = input("Velocity (m/s): "); % 10m/s
Re = density*velocity^2 / (dynVisc*velocity / rootchord);

% Wing Params Chosen: 5 AOA, 3 Washout
AOA = input("Enter Desired Wing Angle of Attack: \n"); % angle of attack
washout = input("Enter Desired Wing Washout: \n"); %angle of washout across 
% airfoil span, degrees
me = velocity/mach;

mass = input("Enter aircraft mass (kg): "); % 3.5kg approx mass of aircraft
areaWing = tipchord*(span*2) + (rootchord-tipchord)*span;
%% Define simulation params
num_of_points = length(alpha1);
n = input("Enter number of bins for simulation (30 recommended): \n"); 
xq = linspace(washout+AOA,AOA,n);

% Now, interpolate the data for selected angles
vq1 = interp1(alpha1,cl1,xq,'spline'); % cl at tip
vq2 = interp1(alpha2,cl2,xq,'spline'); % cl at root
vd1 = interp1(alpha1,cd1,xq,'spline'); % cd at tip
vd2 = interp1(alpha2,cd2,xq,'spline'); % cd at root


% Initialize arrays for spanwise interpolation
cl_interpolate = zeros(1,n);
cd_interpolate = zeros(1,n);
chord_interpolate = zeros(1,n);

% Spanwise interpolation between tip and root
for i = 1:n
    lambda = (i-1)/(n-1);
    cl_interpolate(i) = (1-lambda) * vq2(i) + lambda * vq1(i);
    cd_interpolate(i) = (1-lambda) * vd2(i) + lambda * vd1(i);
    chord_interpolate(i) = (1-lambda) * rootchord + lambda*tipchord;
end

%% Now, calculate lift and drag over the bins defined by n
deltaSpan = span/n;
liftSections = zeros(1,n);
dragSections = zeros(1,n);
% approximation
for i = 1:n
    binArea = deltaSpan * chord_interpolate(i); %Bins for summation
    liftSections(i) = 1/2 * density * velocity^2 * binArea * cl_interpolate(i);
    dragSections(i) = 1/2 * density * velocity^2 * binArea * cd_interpolate(i);
end

liftTotal = sum(liftSections)*2; %assuming two wings simulated, 
wingDragTotal = sum(dragSections)*2;
forceGravity = G * mass;
liftNet = liftTotal - forceGravity;

% Calculate Aspect Ratio
AR = (span*2)^2/( (tipchord*(span*2)) + (rootchord-tipchord)*span );



%% Moving on, let's calculate our performance parameters assuming level 
%  flight
%% Max Speed
% First, define fuselage drag - can just be approximated as a rectangular
% prism, CD of 2.1
cd_Fuselage = input('\nWhat is the coefficient of drag for the fuselage? (ie: 2.1)\n');
area_Fuselage = input('What is the cross sectional area of the fuselage (ie: 0.11m*0.11m)? \n');

% Define the cruise/idle thrust of the motor
motorThrust = input('What is the idle thrust of the motor in kgf? \n') * G;
motorThrustMax = input('What is the max thrust of the motor in kgf? \n') * G;

% Calculate effective drag area for wings
fuselage_areaProduct = area_Fuselage * cd_Fuselage;

AreaProductWings = 0;
for i = 1:n
    binArea = deltaSpan * chord_interpolate(i);
    AreaProductWings = AreaProductWings + (binArea*2) * cd_interpolate(i);
end

% Calculate total area product by adding fuselage area product
totalDragAreaProduct = AreaProductWings + fuselage_areaProduct;

% Now, add an offset since we actually don't really know how much the drag
% actually is
dragOffset = 0.5; % Newtons

% Compute maximum speed algebraically
maxSpeed = sqrt((2 * (motorThrustMax-dragOffset)) / (density * totalDragAreaProduct));
% Compute the idle speed algebraically
idleSpeed = sqrt((2 * (motorThrust-dragOffset)) / (density * totalDragAreaProduct));

% Compute the maximum total drag
totalDrag = 1/2 * density * maxSpeed^2 * totalDragAreaProduct + dragOffset;

fprintf("\nEstimated Max Total Drag + Offset (0.5N): %.2f N\n",totalDrag);
fprintf("Estimated max speed at max thrust: %.2f m/s\n", maxSpeed);
fprintf("Estimated max speed at idle thrust: %.2f m/s\n", idleSpeed);

%% Stall Speed

totalLiftAreaProduct = 0;
for i = 1:n
    binArea = deltaSpan * chord_interpolate(i); %Bins for summation
    totalLiftAreaProduct = totalLiftAreaProduct + (binArea*2) * cl_interpolate(i);
end
stallSpeed = sqrt((2 * (forceGravity)) / (density * totalLiftAreaProduct));
fprintf("Estimated stall speed: %.2f m/s\n", stallSpeed);

%% Takeoff roll
% All SI units, Newtons, kg, m/s^2, seconds
acceleration = motorThrustMax/mass;
timeToStallSpeed = stallSpeed/acceleration;
takeoffRoll = 0*timeToStallSpeed + 1/2 * acceleration*timeToStallSpeed^2;
fprintf("Estimated Forward Acceleration: %.2f m/s^2\n", acceleration);
fprintf("Estimated Time to Takeoff: %.2f s\n", timeToStallSpeed);
fprintf("Estimated Takeoff Roll: %.2f m\n\n", takeoffRoll);

%% Elevator torque calculation
elevatorFull_liftCoef = input("What is the lift coefficient of the elevator " + ...
    "when control surface is fully extended? (ie: 1.2) \n");
elevatorArea = input("What is the area of the elevator? (ie: 0.252m * 0.4m) \n");
MaxElevatorLift = calculateLift(elevatorFull_liftCoef,maxSpeed,density, ...
    elevatorArea);
stallElevatorLift = calculateLift(elevatorFull_liftCoef,stallSpeed,density, ...
    elevatorArea);

leverLength = input("What is the lever length from the aerodynamic " + ...
    "center of the elevator to the center of gravity? (ie: 1.077m) \n");
leverTheta = input("What is the sine ratio of the force relative to the" + ...
    " lever line drawn from the aerodynamic center of the elevator to the " + ...
    "center of gravity? (ie: 0.261/1.077m)\n");
leverTheta = asind(leverTheta);

torqueMax = abs(leverLength*MaxElevatorLift * sind(leverTheta + 90));
torqueStall = abs(leverLength*stallElevatorLift * sind(leverTheta + 90));

fprintf("\nEstimated Max Elevator Lift: %.2f Nm\n", MaxElevatorLift);
fprintf("\nEstimated Max Elevator Torque: %.2f Nm\n", torqueMax);
fprintf("Estimated Stall Speed Elevator Torque: %.2f Nm\n\n", torqueStall);

%% Now, plot the lift
liftSectPlot = figure();
hold on

x= 0:deltaSpan:span-deltaSpan;
xneg= -span+deltaSpan:deltaSpan:0;
U = zeros(1,length(liftSections));
V = liftSections;
Vinv = flip(V);
quiver(x,0,U,V,0,'b.')
quiver(xneg,0,U,Vinv,0,'b.')
xlabel('Spanwise Position (meters)')
ylabel('Lift (Newtons)')

plot(x,V,'r-')
plot(xneg,Vinv,'r-')
txt = {'Net Lift: ',liftNet,'Newtons',' ',mass,'kg ',...
    ' ','Max. Up. Accel. (m/s^2): ',liftNet/mass};
text(xneg(1)-deltaSpan*10,V(n/2-5),txt)
txt = {'Wingspan: ',span*2,'Meters',' ','Chord:',rootchord,'Meters',...
    ' ','AR:',(span*2)^2/(rootchord*(span*2)),' ',...
    'Wing Loading (kg/m^2): ',mass/areaWing};
text(max(x)+x(2),V(n/2-5),txt)

grid on
grid minor

title(strcat('Improved Lift Calculation, Tip: ',Tipname,' Root: ',...
    Rootname,' @  ',num2str(velocity), ...
    'm/s'),strcat(['AOA: ',num2str(AOA)],[' Washout: ', num2str(washout)]))

hold off

%% Now, plot the drag
dragSectPlot = figure();
hold on

x= 0:deltaSpan:span-deltaSpan;
xneg= -span+deltaSpan:deltaSpan:0;
Ud = zeros(1,length(dragSections));
Vd = dragSections;
Vdinv = flip(Vd);
quiver(x,0,Ud,Vd,0,'b.')
quiver(xneg,0,Ud,Vdinv,0,'b.')
xlabel('Spanwise Position (meters)')
ylabel('Drag (Newtons)')

plot(x,Vd,'r-')
plot(xneg,Vdinv,'r-')
txt = {'Total Wing Drag: ',wingDragTotal,'Newtons'};
text(xneg(1)-deltaSpan*10,Vd(6),txt)
txt = {'Wingspan: ',span*2,'Meters',' ','Chord:',rootchord,'Meters',...
    ' ','AR:',(span*2)^2/(rootchord*(span*2)),' ',...
    'Wing Loading (kg/m^2): ',mass/areaWing};
text(max(x)+x(2),Vd(n/2+2),txt)

grid on
grid minor

title(strcat('Improved Drag Calculation, SD7037 @  ',num2str(velocity), ...
    'm/s'),strcat(['AOA: ',num2str(AOA)],[' Washout: ', num2str(washout)]))

hold off

%% Function for calculating lift
function lift = calculateLift(cl,v,rho,area)
    lift = 1/2 * rho * v^2 * area * cl;
end