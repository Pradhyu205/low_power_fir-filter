% Low-power 17-tap FIR model - Author: Pradhyumna D Rao
clc;
clear;
close all;

%% signal
fs = 16000;
t = 0:1/fs:1;

%% input
rng(1);                                                  % fixed seed -> same noise every run
x_clean = sin(2*pi*500*t) + 0.5*sin(2*pi*1200*t);       %original audio
noise = 0.3*randn(size(t)) + 0.3*sin(2*pi*3000*t);      %random noise
x = x_clean + noise;
%% fir parameters 
N = 16;

% Original coefficients (same values as h_values.txt and the Verilog RTL).
% Q8 integers: h = H_int/256, DC gain = 258/256 ~ 1.
H_int = [-1 -1 -2 0 7 19 34 47 52 47 34 19 7 0 -2 -1 -1];
h = H_int / 256;

disp('H values (integer, as used in the Verilog design):');
disp(H_int);

%% default fir
y_normal = filter(h,1,x);

%% pipeline mechanism
% transposed-form FIR (registers between adders), should equal filter()
y_pipe = zeros(size(x));
reg = zeros(1,N);

for n = 1:length(x)
    acc = x(n)*h(1) + reg(1);
    
    for k = 1:N-1
        reg(k) = reg(k+1) + x(n)*h(k+1);
    end
    reg(N) = x(n)*h(N+1);
    
    y_pipe(n) = acc;
end
fprintf('Max |pipeline - filter()| = %g\n', max(abs(y_pipe - y_normal)));

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