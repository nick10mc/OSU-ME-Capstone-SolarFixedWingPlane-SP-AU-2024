%% Flight time and power draw vs sunlight percent
%% By Joey Dalpra
clc;
clear all;
close all;
% Constants
basePowerDraw = 20.475;   % Constant power draw in Watts
throttlePowerStep = 25;   % Increment in power draw for each 10% throttle
batteryCapacity = 1.61;   % Battery capacity in Amp-hours
batteryVoltage = 14.8;    % Assuming a constant 11.1V LiPo battery

% Sunlight percentage and corresponding solar power generation
sunlightPercent = 0:10:100;           % Sunlight percentage from 0% to 100%
solarPowerGen = (sunlightPercent / 100) * 90;  % Solar power generation in Watts

% Throttle percentages from 0% to 100%
throttlePercent = 0:1:10;

% Calculate power draw and flight time for each throttle and sunlight percentage
for i = 1:length(throttlePercent)
    % Calculate total power draw at each throttle setting
    throttlePowerDraw = throttlePercent(i) * throttlePowerStep;
    totalPowerDrawThrottle = basePowerDraw + throttlePowerDraw;
    
    % Preallocate arrays for current throttle level
    powerDraw = zeros(1, length(sunlightPercent));
    flightTime = zeros(1, length(sunlightPercent));
    
    for j = 1:length(sunlightPercent)
        % Calculate battery power draw by subtracting solar power generation
        batteryPowerDraw = totalPowerDrawThrottle - solarPowerGen(j);
        
        % Store power draw values
        powerDraw(j) = batteryPowerDraw;
        
        % Calculate flight time (in minutes)
        if batteryPowerDraw > 0
            flightTime(j) = batteryCapacity/(batteryPowerDraw/batteryVoltage)*60;
        else
            flightTime(j) = Inf; % Infinite flight time if solar power fully sustains the draw
        end
    end
    
    % Plot Battery Power Draw vs Sunlight % for current throttle
    figure;
    plot(sunlightPercent, powerDraw, '-o', 'LineWidth', 1.5);
    xlabel('Sunlight Percentage (%)');
    ylabel('Battery Power Draw (Watts)');
    title(sprintf('Battery Power Draw vs Sunlight Percentage (Throttle %d0%%)', throttlePercent(i)));
    grid on;
    
    % Plot Flight Time vs Sunlight % for current throttle
    figure;
    plot(sunlightPercent, flightTime, '-o', 'LineWidth', 1.5);
    xlabel('Sunlight Percentage (%)');
    ylabel('Flight Time (Minutes)');
    title(sprintf('Flight Time vs Sunlight Percentage (Throttle %d0%%)', throttlePercent(i)));
    grid on;
end

%% Optimal Flight time
clc;
clear all;
close all;

% Constants
basePowerDraw = 20.475;            % Constant power draw in Watts
throttlePowerStep = 25;            % Increment in power draw for each 10% throttle
batteryCapacity = 1.61;            % Battery capacity in Amp-hours
batteryVoltage = 14.8;             % Battery voltage in Volts
sunlightPercent = 0:10:100;        % Sunlight percentage from 0% to 100%
solarPowerGen = (sunlightPercent / 100) * 90;  % Solar power generation in Watts

% Define throttle settings for takeoff and cruise
takeoffThrottle = 100;             % 100% throttle for takeoff
cruiseThrottles = 30:10:100;       % Cruise throttles from 30% to 100%

% Takeoff phase (100% throttle) - Assume a fixed short takeoff time (e.g., 1 minute)
takeoffTimeMinutes = 1;            % Set desired takeoff time in minutes

% Initialize a matrix to store flight times for each throttle setting and sunlight percentage
flightTimeMatrix = zeros(length(cruiseThrottles), length(sunlightPercent));

% Loop through each cruise throttle setting
for k = 1:length(cruiseThrottles)
    cruiseThrottle = cruiseThrottles(k);
    
    % Calculate total power draw at takeoff and cruise settings
    takeoffPowerDraw = basePowerDraw + (takeoffThrottle / 10) * throttlePowerStep;
    cruisePowerDraw = basePowerDraw + (cruiseThrottle / 10) * throttlePowerStep;
    
    % Initialize array to store results for the current throttle
    totalFlightTime = zeros(1, length(sunlightPercent));
    
    % Calculate flight times for each sunlight percentage
    for j = 1:length(sunlightPercent)
        % Solar power generation at current sunlight percentage
        solarPower = solarPowerGen(j);
        
        % Calculate battery power draw during takeoff and cruise
        batteryPowerDrawTakeoff = takeoffPowerDraw - solarPower;
        batteryPowerDrawCruise = cruisePowerDraw - solarPower;
        
        % Check if solar power sustains draw (negative draw means infinite flight time)
        if batteryPowerDrawTakeoff <= 0 && batteryPowerDrawCruise <= 0
            totalFlightTime(j) = Inf; % Infinite flight time if solar power fully sustains the draw
            continue;
        end
        
        % Takeoff phase (100% throttle) - Calculate battery usage
        batteryUsedTakeoff = (batteryPowerDrawTakeoff / batteryVoltage) * (takeoffTimeMinutes / 60); % Ah used in takeoff

        % Remaining battery capacity after takeoff
        remainingBatteryCapacity = batteryCapacity - batteryUsedTakeoff;
        
        % Check if battery is depleted after takeoff
        if remainingBatteryCapacity <= 0
            totalFlightTime(j) = takeoffTimeMinutes; % Only takeoff time available
            continue;
        end
        
        % Cruise phase - Calculate remaining flight time
        if batteryPowerDrawCruise > 0
            cruiseTimeMinutes = (remainingBatteryCapacity / (batteryPowerDrawCruise / batteryVoltage)) * 60;
        else
            cruiseTimeMinutes = Inf; % Infinite cruise time if solar power sustains draw at cruise
        end
        
        % Total flight time (takeoff + cruise)
        totalFlightTime(j) = takeoffTimeMinutes + cruiseTimeMinutes;
    end
    
    % Store the total flight time for the current throttle in the matrix
    flightTimeMatrix(k, :) = totalFlightTime;
    
    % Plot Optimal Flight Time vs Sunlight % for the current cruise throttle
    figure;
    plot(sunlightPercent, totalFlightTime, '-o', 'LineWidth', 1.5);
    xlabel('Sunlight Percentage (%)');
    ylabel('Optimal Flight Time (Minutes)');
    title(sprintf('Optimal Flight Time vs Sunlight Percentage (Cruise Throttle %d%%)', cruiseThrottle));
    grid on;
end
