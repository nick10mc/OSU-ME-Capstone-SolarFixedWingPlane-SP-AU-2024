%% Sunlight percentage for each day of the year in Columbus, Ohio
%% By Joey Dalpra
clc;
close all;
clear all;

% Constants for Columbus, Ohio
latitude = 40.0; % Latitude of Columbus in degrees
daysInYear = 365;
sunlightPercent = zeros(1, daysInYear);

% Define the number of days in each month
daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

% Function to calculate solar declination for a given day of the year
solarDeclination = @(n) 23.44 * sind((360/365) * (n - 81));

% Loop through each day of the year
for day = 1:daysInYear
    % Solar declination for the current day
    delta = solarDeclination(day);
    
    % Calculate solar altitude at solar noon
    solarAltitude = asind(sind(latitude) * sind(delta) + cosd(latitude) * cosd(delta));
    
    % Normalize solar altitude to get sunlight percentage
    sunlightPercent(day) = (solarAltitude / 90) * 100; % Maximum is 100% when directly overhead
end

% Create vectors for each month
January = sunlightPercent(1:31);
February = sunlightPercent(32:59);
March = sunlightPercent(60:90);
April = sunlightPercent(91:120);
May = sunlightPercent(121:151);
June = sunlightPercent(152:181);
July = sunlightPercent(182:212);
August = sunlightPercent(213:243);
September = sunlightPercent(244:273);
October = sunlightPercent(274:304);
November = sunlightPercent(305:334);
December = sunlightPercent(335:365);
plot([1:1:30],November);
xlabel('Day')
ylabel('Sunlight Percentage')
title('Sunlight Percentage for Month of November')

% Constants
basePowerDraw = 20.475;   % Constant power draw in Watts
throttlePowerStep = 25;   % Increment in power draw for each 10% throttle
batteryCapacity = 1.61;   % Battery capacity in Amp-hours
batteryVoltage = 14.8;    % Battery voltage in Volts
takeoffThrottle = 100;    % Throttle percentage for takeoff phase
cruiseThrottle = 30;      % Throttle percentage for cruise phase
takeoffTimeMinutes = 1;   % Duration of takeoff phase in minutes

% Use November sunlight percentage data (Days 305 to 334)
November = sunlightPercent(305:334);  % Sunlight percentages for each day in November

% Preallocate array for total flight time for each day
totalFlightTimeNovember = zeros(1, length(November));

% Loop through each day of November
for day = 1:length(November)
    dailySunlightPercent = November(day); % Get sunlight percentage for the current day
    solarPowerGen = (dailySunlightPercent / 100) * 90; % Solar power generation in Watts

    % Takeoff power draw calculation
    takeoffPowerDraw = basePowerDraw + (takeoffThrottle / 10) * throttlePowerStep;
    batteryPowerDrawTakeoff = takeoffPowerDraw - solarPowerGen;
    batteryUsedTakeoff = max((batteryPowerDrawTakeoff / batteryVoltage) * (takeoffTimeMinutes / 60), 0); % Ah used in takeoff

    % Remaining battery capacity after takeoff
    remainingBatteryCapacity = batteryCapacity - batteryUsedTakeoff;

    % Cruise phase power draw calculation
    cruisePowerDraw = basePowerDraw + (cruiseThrottle / 10) * throttlePowerStep;
    batteryPowerDrawCruise = cruisePowerDraw - solarPowerGen;

    % Calculate remaining flight time during cruise phase
    if batteryPowerDrawCruise > 0 && remainingBatteryCapacity > 0
        cruiseTimeMinutes = (remainingBatteryCapacity / (batteryPowerDrawCruise / batteryVoltage)) * 60;
    else
        cruiseTimeMinutes = Inf; % Infinite flight time if solar power fully sustains draw at cruise
    end

    % Total flight time (takeoff + cruise)
    totalFlightTimeNovember(day) = takeoffTimeMinutes + cruiseTimeMinutes;
end

% Plot Total Flight Time vs Day of November
figure;
plot(1:length(November), totalFlightTimeNovember, '-o', 'LineWidth', 1.5);
xlabel('Day of November');
ylabel('Total Flight Time (Minutes)');
title('Total Flight Time vs Day of November (100% Takeoff for 1 min, 30% Cruise)');
grid on;
% Plot the sunlight percentage for each day of the year
figure;
plot(1:daysInYear, sunlightPercent, '-b', 'LineWidth', 1.5);
xlabel('Day of the Year');
ylabel('Sunlight Percentage (%)');
title('Estimated Sunlight Percentage for Each Day of the Year in Columbus, Ohio');
grid on;
figure;
plot(1:daysInYear, sunlightPercent*.90, '-b', 'LineWidth', 1.5);
xlabel('Day of the Year');
ylabel('Solar Power Output (W)');
title('Estimated Solar Power Output for Each Day of the Year in Columbus, Ohio');
grid on;

% Preallocate arrays for flight times and sunlight data
flightTimes = zeros(15, 24);  % 15 days (16th to 30th) x 24 hours

% Preallocate hourly sunlight data for the 16th to 30th of November
hourlySunlightPercent = zeros(15, 24);  % 15 days x 24 hours

% Loop through each day from the 16th to 30th of November
for day = 16:30
    dayIndex = day - 15;  % Index for accessing the sunlight data
    
    % Calculate hourly sunlight percentage for the current day
    for hour = 1:24
        time_angle = (hour - 12) * 15;  % Time-based angle shift (each hour is 15 degrees)
        delta = solarDeclination(day);  % Solar declination for the day
        solarAltitude = asind(sind(latitude) * sind(delta) + cosd(latitude) * cosd(delta) * cosd(time_angle));
        
        % Normalize solar altitude to get sunlight percentage
        if solarAltitude < 0
            solarAltitude = 0;  % Set to 0% if the sun is below the horizon
        end
        
        hourlySunlightPercent(dayIndex, hour) = (solarAltitude / 90) * 100;  % Max is 100% when directly overhead
    end
    
    % Calculate flight time for each hour of the current day
    for hour = 1:24
        dailySunlightPercent = hourlySunlightPercent(dayIndex, hour);  % Sunlight percentage for the current hour
        solarPowerGen = (dailySunlightPercent / 100) * 90;  % Solar power generation in Watts
        
        % Takeoff power draw calculation
        takeoffPowerDraw = basePowerDraw + (takeoffThrottle / 10) * throttlePowerStep;
        batteryPowerDrawTakeoff = takeoffPowerDraw - solarPowerGen;
        batteryUsedTakeoff = max((batteryPowerDrawTakeoff / batteryVoltage) * (takeoffTimeMinutes / 60), 0);  % Ah used in takeoff
        
        % Remaining battery capacity after takeoff
        remainingBatteryCapacity = batteryCapacity - batteryUsedTakeoff;
        
        % Cruise phase power draw calculation
        cruisePowerDraw = basePowerDraw + (cruiseThrottle / 10) * throttlePowerStep;
        batteryPowerDrawCruise = cruisePowerDraw - solarPowerGen;
        
        % Calculate remaining flight time during cruise phase
        if batteryPowerDrawCruise > 0 && remainingBatteryCapacity > 0
            cruiseTimeMinutes = (remainingBatteryCapacity / (batteryPowerDrawCruise / batteryVoltage)) * 60;
        else
            cruiseTimeMinutes = Inf;  % Infinite flight time if solar power fully sustains draw at cruise
        end
        
        % Total flight time for this hour
        flightTimes(dayIndex, hour) = takeoffTimeMinutes + cruiseTimeMinutes;
    end
end

% %% Plotting: Sunlight Percentage vs. Time of Day for Each Day from 16th to 30th of November
% for day = 1:15
%     figure;
%     plot(1:24, hourlySunlightPercent(day, :), 'LineWidth', 1.5);
%     xlabel('Time of Day (Hour)');
%     ylabel('Sunlight Percentage (%)');
%     title(['Sunlight Percentage vs. Time of Day (November ' num2str(31 - day) ')']);
%     grid on;
% end
% 
% %% Plotting: Flight Time vs. Time of Day for Each Day from 16th to 30th of November
% for day = 1:15
%     figure;
%     plot(1:24, flightTimes(day, :), 'LineWidth', 1.5);
%     xlabel('Time of Day (Hour)');
%     ylabel('Flight Time (Minutes)');
%     title(['Flight Time vs. Time of Day (November ' num2str(31-day) ')']);
%     grid on;
% end
for day = 1:15
    figure;
    plot(1:24, hourlySunlightPercent(day, :)*.9, 'LineWidth', 1.5);
    xlabel('Time of Day (Hour)');
    ylabel('Solar Power Output (W)');
    title(['Solar Power Output vs. Time of Day (November ' num2str(31 - day) ')']);
    grid on;
end
