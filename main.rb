def machineListToHash(machineList)
  machineHash = {}
  machineList.each do |machine|
    if !machineHash.key?(machine.chemA)
      machineHash[machine.chemA] = {}
    end
    machineHash[machine.chemA][machine.chemB] = machine
  end
  machineHash
end

def readMachines(file)
  machineList = Array.new
  while (line = file.gets)
    array = line.split
    chem1 = array[1].to_sym
    chem2 = array[2].to_sym
    machineList.push(Machine.new(chem1, chem2, array[3].to_i, array[0].delete("M").to_i))
  end
  machineList
end

class MinScore
  include Comparable
  @@invalidScore = 2 ** 30
  def self.invalidScore
    @@invalidScore
  end
  attr_reader :score
  attr_reader :machines

  def <=>(anOther) #use score when comparing
    if anOther.score == @@invalidScore
      return -1
    end
    @score <=> anOther.score
  end
  def initialize(score, machines)
    @score = score
    @machines = machines
  end
  def to_s()
    output = ""
    if @score == @@invalidScore
      output = "This is an invalid solution"
    else
      output += "#{@score}\n"
      machineNumbers = Array.new
      @machines.each do |machine|
        machineNumbers.push(machine.name)
      end
      machineNumbers.sort!
      output += machineNumbers.join(" ") + "\n"
    end
    output
  end
end

$iterations = 0

class Machine
  include Comparable
  attr_reader :chemA
  attr_reader :chemB
  attr_reader :cost
  attr_reader :name

  def initialize(chemA, chemB, cost, name)
    @chemA = chemA
    @chemB = chemB
    @cost = cost
    @name = name
  end
  def to_s()
    return @name.to_s
  end
end

class Machines
  attr_accessor :connected
  attr_accessor :cost
  attr_accessor :score
  attr_accessor :remainingMachines
  attr_accessor :usedMachines
  attr_accessor :fullyConnected
  attr_accessor :unusedMachines
  @@minScore = MinScore.invalidScore
  def self.setHash(machineHash)
    @@machineHash = machineHash
    chemArray = @@machineHash.keys
    @@size = chemArray.size
    @@chemHash = {}
    chemArray.each_index do |index|
      @@chemHash[chemArray[index]] = index
    end
  end
  def initialize(remainingMachines=nil, machinesState=nil)
    @connected = Array.new(@@size)
    @connected.each_index do |index|
      if !machinesState.nil?
        @connected[index] = Array.new(machinesState.connected[index])
        @cost = machinesState.cost
        @score = machinesState.score
        @usedMachines = Array.new(machinesState.usedMachines)
        @remainingMachines = Array.new
        @fullyConnected = machinesState.fullyConnected
      else
        @connected[index] = Array.new(@@size)
        @cost = 0
        @score = 0
        @usedMachines = Array.new
        @remainingMachines = remainingMachines
        @fullyConnected = false
      end
    end
  end
  def doesMachineHelp(machine)
    if (@cost + machine.cost) > @@minScore
      return false
    end
    if @connected[@@chemHash[machine.chemA]][@@chemHash[machine.chemB]].nil?
      return true
    end
    return false
  end
  def addMachine(machine)
    withoutMachine = self.copy()
    @unusedMachines.push(withoutMachine)
    minimal = true
    @cost += machine.cost
    chemA = @@chemHash[machine.chemA]
    chemB = @@chemHash[machine.chemB]
    @connected[chemA][chemB] = machine.name
    for i in 0..@connected.size-1
      if !@connected[chemB][i].nil?
        @connected[chemA][i] = true
      end
    end
    for i in 0..(@@size-1)
      if !@connected[i][chemA].nil?
        for j in 0..(@@size - 1)
          if !@connected[chemA][j].nil?
            if @connected[i][j] == true || !@connected[i][j]
              @connected[i][j] = true
            else
              minimal = false
            end
          end
        end
      end
    end
    self.doScore()
    @usedMachines.push(machine)
    return minimal
  end
  def fullyConnected()
    @connected.each_index do |i|
      @connected[i].each_index do |j|
        if i != j && @connected[i][j].nil?
          return false
        end
      end
    end
    return true
  end
  def doScore()
    score = 0
    @connected.each_index do |i|
      @connected[i].each_index do |j|
        if i != j && @connected[i][j]
          score += 1
        end
      end
    end
    @score = score
    if @score == (@@size ** 2 - @@size)
      @fullyConnected = true
    end
  end
  def heuristic()
    return @cost.to_f / @score
  end
  def orderRemainingMachines()
    machinesStates = []
    @remainingMachines.each do |machine|
      if self.doesMachineHelp(machine)
        machinesState = self.copy()
        helped = machinesState.addMachine(machine)
        if helped
          machinesStates.push(machinesState)
        end
      end
    end
    machinesStates.sort! { |a,b|  a.heuristic() <=> b.heuristic() }
    remainingMachines = Array.new
    machinesStates.each_index do |index|
      remainingMachines[index] = machinesStates[index].usedMachines.last
    end
    returnMachinesStates = Array.new
    i = 0
    machinesStates.each_index do |index|
      machinesStates[index].remainingMachines = remainingMachines.slice(index+1, remainingMachines.size-1)
      if machinesStates[index].possibleWithRemaining()
        returnMachinesStates[i] = machinesStates[index]
        i += 1
      end
    end
    returnMachinesStates
  end
  def copy()
    Machines.new(nil, self)
  end
  def printMachines()
    output = "#{@cost}: "
    machineNumbers = Array.new
    @usedMachines.each do |machine|
      machineNumbers.push(machine.name)
    end
    #machineNumbers.sort!
    output += machineNumbers.join(" ") + "\n"
    return output
  end
  def findCheapestMachines()
    return recursiveExplore()
  end
  def addNeededMachines()
    inUsedHash = {}
    outUsedHash = {}
    inRemainingHash = {}
    outRemainingHash = {}
    @usedMachines.each do |machine|
      if !inUsedHash[machine.chemB]
        inUsedHash[machine.chemB] = Array.new
      end
      inUsedHash[machine.chemB].push(machine)
      if !outUsedHash[machine.chemA]
        outUsedHash[machine.chemA] = Array.new
      end
      outUsedHash[machine.chemA].push(machine)
    end
    @remainingMachines.each do |machine|
      if !inRemainingHash[machine.chemB]
        inRemainingHash[machine.chemB] = Array.new
      end
      inRemainingHash[machine.chemB].push(machine)
      if !outRemainingHash[machine.chemA]
        outRemainingHash[machine.chemA] = Array.new
      end
      outRemainingHash[machine.chemA].push(machine)
    end
    alreadyUsed = {}
    inRemainingHash.each do |chem, machines|
      if !inUsedHash[chem]
        if inRemainingHash[chem] && inRemainingHash[chem].size == 1
          minimal = addMachine(machines[0])
          if !minimal
            return false
          end
          alreadyUsed[machines[0]] = true
          @remainingMachines.delete(machines[0])
        end
      end
      return true
    end
    outRemainingHash.each do |chem, machines|
      if !outUsedHash[chem]
        if outRemainingHash[chem] && outRemainingHash[chem].size == 1 && !alreadyUsed[machines[0]]
          minimal = addMachine(machines[0])
          if !minimal
            return false
          end
          @remainingMachines.delete(machines[0])
        end
      end
    end
  end
  def possibleWithRemaining()
    if @fullyConnected
      return true
    end
    machinesState = self.copy()
    @remainingMachines.each do |machine|
      machinesState.addMachine(machine)
      if machinesState.fullyConnected
        return true
      end
    end
    return false
  end
  def recursiveExplore()
    $iterations += 1
    #puts printMachines()
    if @cost >= @@minScore
      return MinScore.new(@cost, @usedMachines)
    end
    unless @fullyConnected
      scores = Array.new
      addNeededMachines()
      minimal = true
      if @cost >= @@minScore || !minimal
        return MinScore.new(@cost, @usedMachines)
      end
      nextMachineStates = orderRemainingMachines()
      nextMachineStates.each do |nextMachineState|
        scores.push(nextMachineState.recursiveExplore())
      end
      if scores.size == 0
        return MinScore.new(MinScore.invalidScore, @usedMachines)
      else
        return scores.min
      end
    else
      if @cost < @@minScore
        @@minScore = @cost
        puts "#{$iterations} #{@cost}"
        puts printMachines()
      end
    end
    return MinScore.new(@cost, @usedMachines)
  end

end


File.open('input/example_2.ex', 'r') do |file|
  t0 = Time.now
  machineList = readMachines(file)
  machineHash = machineListToHash(machineList)
  Machines.setHash(machineHash)
  machines = Machines.new(machineList)
  minMachines = machines.findCheapestMachines()
  puts minMachines
  print "Iterations: " + $iterations.to_s + " Time " + (Time.now - t0).to_s
end


