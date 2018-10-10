%% 2 dimensional nonlinear system with dynamics
%% x = A + x * x * y - B * x - x
%% y = B * x - x * x * y
%% Computing basis vectors for each pair of trajectories


clear all;
clc;

no_of_dims = 2
no_of_trajs = 10
traj_combs = combnk(1:no_of_trajs,2)
[no_of_samples, dim2] = size(traj_combs);
init_state_array = rand(no_of_samples,no_of_dims)*10

%% Time

tspan = 0:0.01:10;

%% Integration/Simulation

for idx = 1:no_of_samples
	init_state = init_state_array(idx,:);
	[t x] = ode45(@dxdt,tspan,init_state);
	traj_t(:,idx) = t;
	traj_x(:,:,idx) = x;
end

[time_steps elements] = size(traj_t)
x_v_t_inputs = zeros(no_of_dims*2+1, (no_of_samples-1)*(time_steps-1))
x_v_outputs = zeros(no_of_dims*2, (no_of_samples-1)*(time_steps-1))
for idx = 1:no_of_samples
	trajs = traj_combs(idx, :);		
	central_traj = traj_x(:, :, trajs(1));
	second_traj = traj_x(:, :, trajs(2));	
	for idy = 1:(time_steps-1)
		x_val = central_traj(idy, :);
        	v_val = second_traj(idy,:) - x_val; 
        	time_step = traj_t(idy, idx);
		x_v_t_inp_pair = [x_val v_val time_step];
        	x_prime_val = central_traj(idy+1, :);
        	v_prime_val = second_traj(idy+1, :) - x_prime_val;
        	x_v_oup_pair = [x_prime_val, v_prime_val];
		x_v_t_inputs(:, (idx-1)*(time_steps-1) + idy) = x_v_t_inp_pair;
		x_v_outputs(:, (idx-1)*(time_steps-1) + idy) = x_v_oup_pair;
	end
end

inputSeries = con2seq(x_v_t_inputs);
targetSeries = con2seq(x_v_outputs);

[cell_dim1 cell_dim2] = size(inputSeries);
total_points = 1:1:cell_dim2;
total_points = total_points(randperm(length(total_points)));
no_train_samples = (cell_dim2*2)/3;
no_test_samples = cell_dim2 - no_train_samples;
train_input = cell(1, no_train_samples);
train_target = cell(1, no_train_samples);
test_input = cell(1, no_test_samples);
test_target = cell(1, no_test_samples);
for idx = 1:no_train_samples
    train_input(idx) = inputSeries(total_points(idx));
    train_target(idx) = targetSeries(total_points(idx));
end
for idx = 1:no_test_samples
    test_input(idx) = inputSeries(total_points(no_train_samples+idx));
    test_target(idx) = targetSeries(total_points(no_train_samples+idx));
end

net = feedforwardnet(10);
net.trainParam.epochs = 100;
[net tr] = train(net,train_input, train_target);

% View the Network
view(net)
wts = getwb(net);
[b, IW, LW] = separatewb(net, wts);
%weights = net.IW{1,1};
%bias = net.b{1};

outputs = net(test_input);
perf = perform(net,outputs,test_target)

output_mat = cell2mat(outputs);
target_mat = cell2mat(test_target);
output_x_v_values = output_mat(1:2,:)+output_mat(3:4,:);
target_x_v_values = target_mat(1:2,:)+target_mat(3:4,:);
[dim1 dim2] = size(output_mat);
total_output_points = 1:1:dim2;
figure(1);
clf;
xlabel('Time');
title('Brusselator');
legend('Output','Target');
subplot(3,1,1);
plot(output_x_v_values(1,:), output_x_v_values(2,:), target_x_v_values(1,:), target_x_v_values(2,:));
subplot(3,1,2);
plot(total_output_points(1,:), output_x_v_values(1,:), total_output_points(1,:), target_x_v_values(1,:))
subplot(3,1,3);
plot(total_output_points(1,:), output_x_v_values(2,:), total_output_points(1,:), target_x_v_values(2,:))
	
% ============================================================================================
% dvdt
% ============================================================================================

function dv = dxdt(t,v)

%%% parameter set 1

A=1;
B=1.5;

%%% variables

x=v(1);
y=v(2);
%%% equations

dv = [
    A + x*x*y - B*x - x;  % dx/dt
    B*x-x*x*y;  	% dy/dt
] ;
end
