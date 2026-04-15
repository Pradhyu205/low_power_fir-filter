clc;
clear;
close all;

%% signal
fs = 16000;
t = 0:1/fs:1;

%% input
x_clean = sin(2*pi*500*t) + 0.5*sin(2*pi*1200*t);       %original audio
noise = 0.3*randn(size(t)) + 0.3*sin(2*pi*3000*t);      %random noise
x = x_clean + noise;
%% fir parameters 
N = 16;
fc = 1500;
h = fir1(N, fc/(fs/2));

%% default fir
y_normal = filter(h,1,x);

%% pipeline mechanism
y_pipe = zeros(size(x));
reg = zeros(1,N+1);

for n = 1:length(x)
    acc = x(n)*h(1);
    
    for k = 2:N+1
        reg(k-1) = reg(k-1) + x(n)*h(k);
        acc = acc + reg(k-1);
    end
    
    y_pipe(n) = acc;
end

%% low power
h_q = round(h*64)/64;   % Lower precision → low power
y_low = filter(h_q,1,x);

%% power difference reference
power_normal = sum(abs(y_normal).^2);
power_low = sum(abs(y_low).^2);

%% all figures 
figure;

subplot(4,1,1);
plot(t, x);
title('Input Signal');

subplot(4,1,2);
plot(t, y_normal);
title('Normal FIR Output');


subplot(4,1,3);
plot(t, y_low);
title('Low-Power FIR Output');


figure;

subplot(3,1,1);
plot(t, x_clean);
title('Original Audio Signal');

subplot(3,1,2);
plot(t, x);
title('Noisy Audio Signal');

subplot(3,1,3);
plot(t, y_low);
title('Filtered Audio (Noise Removed)');



figure;

subplot(2,1,1);
plot(t, y_normal);
title('Normal FIR Output');

subplot(2,1,2);
plot(t, y_low);
title('Low-Power FIR Output');


figure;

plot(t, y_normal - y_low);
title('Error between Normal and Low-Power FIR');
xlabel('Time');
ylabel('Error');
grid on;
%% power reference---------No unit
fprintf('Power (Normal): %.2f\n', power_normal);
fprintf('Power (Low Power): %.2f\n', power_low);
power_reduction = ((power_normal - power_low)/power_normal)*100;
fprintf('Power Reduction: %.2f %%\n', power_reduction);