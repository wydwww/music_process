require 'torch'
require 'nn'
require 'optim'


dofile 'data.lua'
-- 30-classes classification problem
classes = {'A4', 'B3', 'B4', 'C3', 'C3A4', 'C3B4', 'C3C4', 'C3D4', 'C3E4', 'C3F4', 'C3G4', 'C4', 'C4A4', 'C4AS4', 'C4B4', 'C4CS4', 'C4D4', 'C4DS4', 'C4E4', 'C4E4G4', 'C4F4', 'C4FS4', 'C4G4', 'C4GS4', 'C5', 'D4', 'D4E4F4', 'E4', 'F4', 'G4'}
trSize = 9600
teSize = 2393
-- SGD
torch.setdefaulttensortype('torch.FloatTensor')
batchSize = 1
learningRate = 0.01
momentum = 0

-- creat a multi-layer perceptron
mlp = nn.Sequential()
inputs = 4000 -- the number of input dimensions
outputs = 30 -- number of classifications
HUs = 100 -- hidden units
mlp:add( nn.Linear(inputs, HUs) )
mlp:add( nn.Tanh() ) -- some hyperbolic tangent transfer function
mlp:add( nn.Linear(HUs, outputs) )
mlp:add( nn.LogSoftMax() )

-- retrieve parameters and gradients
parameters,gradParameters = mlp:getParameters()

criterion = nn.ClassNLLCriterion()

-- load train and test data
setmetatable(trainData, 
    {__index = function(t, i) 
                    return {t.data[i], t.labels[i]} 
                end}
)

setmetatable(testData,
    {__index = function(t, i)
                    return {t.data[i], t.labels[i]}
                end}
)

--testData = torch.load('test.t7')

-- basic trainer
--trainer = nn.StochasticGradient(mlp, criterion)
--trainer.learningRate = 0.01
--trainer:train(trainData)

-- train function
function train()
   -- epoch tracker
   epoch = epoch or 1

   -- local vars
   local time = sys.clock()

   shuffle = torch.randperm(9600)
   -- do one epoch
   print('<trainer> on training set:')
   print("<trainer> online epoch # " .. epoch .. ' [batchSize = ' .. batchSize .. ']')
   for t = 1,trainData:size(),batchSize do
      -- create mini batch
      local inputs = torch.Tensor(batchSize,4000)
      local targets = torch.Tensor(batchSize)
      local k = 1
      for i = t,math.min(t+batchSize-1,trainData:size()) do
         -- load new sample
         inputs[k] = trainData.data[i]
         targets[k] = trainData.labels[i]
         k = k + 1
      end

      -- create closure to evaluate f(X) and df/dX
      local feval = function(x)
         -- just in case:
         collectgarbage()

         -- get new parameters
         if x ~= parameters then
            parameters:copy(x)
         end

         -- reset gradients
         gradParameters:zero()

         -- evaluate function for complete mini batch
         local outputs = mlp:forward(inputs)
         local f = criterion:forward(outputs, targets)
         
         -- estimate df/dW
         local df_do = criterion:backward(outputs, targets)
         mlp:backward(inputs, df_do)

         print('loss: ' .. f)
         -- return f and df/dX
         return f,gradParameters
      end

      -- Perform SGD step:
      sgdState = sgdState or {
         learningRate = learningRate,
         momentum = momentum,
         learningRateDecay = 5e-7,
         weightDecay = 0
      }
      optim.sgd(feval, parameters, sgdState)
      -- disp progress
      xlua.progress(t, trainData:size())
   end
  
   -- time taken
   time = sys.clock() - time
   time = time / trainData:size()
   print("<trainer> time to learn 1 sample = " .. (time*1000) .. 'ms')
   -- print loss

   -- save/log current net
   local filename = './model.net'
   os.execute('mkdir -p ' .. sys.dirname(filename))
   print('==> saving model to '..filename)
   torch.save(filename, mlp)

   epoch = epoch + 1
end

-- test function
function test()
   -- local vars
   local time = sys.clock()
   correct = 0
   -- test over given dataset
   for t = 1, teSize, batchSize do
      -- disp progress
      xlua.progress(t, teSize)

      -- create mini batch
      local inputs = torch.Tensor(batchSize,4000)
      local targets = torch.Tensor(batchSize)
      local k = 1
      for i = t,math.min(t+batchSize-1, teSize) do
         -- load new sample
         inputs[k] = testData.data[i]
         targets[k] = testData.labels[i]
         k = k + 1
      end

      -- test samples
      local preds = mlp:forward(inputs)
      local confidences, indices = torch.sort(preds, true)  -- true means sort in descending order
      for j = 1, targets:size(1) do
         if targets[j] == indices[j][1] then
            correct = correct + 1
         end
      end
   end

   -- timing
   time = sys.clock() - time
   time = time / teSize
   print("<trainer> time to test 1 sample = " .. (time*1000) .. 'ms')
   print('corrent: ' .. correct)
   print('accuracy: ' .. (correct/teSize*100) .. '%')
end

-- start!
while true do
   train()
   test()
end
-- a simple tester
--pred = mlp:forward(testData.data)
--correct = 0
--for i = 1, 2402 do
--    local groundtruth = testData.labels[i]
--    local prediction = mlp:forward(testData.data[i])
--    local confidences, indices = torch.sort(prediction, true)  -- true means sort in descending order
--    if groundtruth == indices[1] then
--        correct = correct + 1
--    end
--end

