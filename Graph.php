<?php

class Graph {
	
	private $numChemicals;
	private $chemicals;
	private $matrix;
	private $machines;
	private $bestMachines;
	private $bestCost = false;
	
	function __construct($machines, $chemicals) {
		$this->chemicals = $chemicals;
		$this->numChemicals = count($chemicals);
		$this->matrix = array_fill_keys(array_keys($chemicals), $chemicals);
		$this->machines = $machines;
		foreach ($machines as $row) {
			if (!array_key_exists($row["chemB"], $chemicals)) {
				throw new Exception("Invalid input: can't start with " . $row["chemB"]);
			}
			$this->matrix[$row["chemA"]][$row["chemB"]] = array("name" => $row["machine"], "cost" => $row["cost"]);
		}
		
	}
	
	public static function readMachines($file) {
		$handle = @fopen($file, "r");
		$machines = array();
		$chemicals = array();
		if ($handle) {
			while ($line = trim(fgets($handle))) {
				$row = preg_split('/\s+/', $line);
				$machines[] = array(
					"machine"	=> $row[0],
					"chemA" => $row[1], 
					"chemB" => $row[2], 
					"cost" => $row[3]
				);
				$chemicals[$row[1]] = 0;
			}
		}
		return new Graph($machines, $chemicals);
		
	}
	
	private function removeRedundantMachines() {
		
	}
	
	public function preProcess() {
		
	}
	
	private function addMachineToConnections($machineIndex, $connections) {
		$newConnections = $connections;
		$chemA = $this->machines[$machineIndex]["chemA"];
		$chemB = $this->machines[$machineIndex]["chemB"];
		
		$chemAIn = array($chemA);
		foreach ($connections as $currentChemA => $chemBArray) {
			if ($connections[$currentChemA][$chemA]) {
				$chemAIn[] = $currentChemA;
			}
		}
		$chemBOut = array($chemB);
		foreach ($connections[$chemB] as $currentChemB => $connected) {
			if ($connected) {
				$chemBOut[] = $currentChemB;
			}
		}
		foreach ($chemAIn as $chemA) {
			foreach ($chemBOut as $chemB) {
				$newConnections[$chemA][$chemB] = 1;
			}
		}
		//$machine = $this->machines[$machineIndex];
		//$newConnections[$machine["chemA"]][$machine["chemB"]] = 1;
		return $newConnections;
	}
	
	private function isFullyConnected($connections) {
		foreach ($connections as $chemA => $chemBArray) {
			foreach ($chemBArray as $chemB => $connected) {
				if (!(($chemA == $chemB) || $connected)) {
					return false;
				}
			}
		}
		return true;
	}
	
	private function findCheapestMachineSet($usedMachines, $remainingMachines, $connections, $cost) {
		$numNoHelp = 0;
		print join(" ", $usedMachines) . "\n";
		if ($this->isFullyConnected($connections)) {
			if (!$this->bestCost || $cost < $this->bestCost) {
				print $cost . "\n";
				$this->bestCost = $cost;
				$this->bestMachines = $usedMachines;
			}
			return;
		}
		foreach ($remainingMachines as $i => $machineIndex) {
			$machine = $this->machines[$machineIndex];
			if ($connections[$machine["chemA"]][$machine["chemA"]]) {
				$numNoHelp++;
				continue;
			}
			$newCost = $cost + $machine["cost"];
			if ($this->bestCost && ($newCost >= $this->bestCost)) {
				continue;
			}
			$newRemainingMachines = array_slice($remainingMachines, $i + 1);

			if () {
				
			}
			$newUsedMachines = $usedMachines;
			$newUsedMachines[] = $machineIndex;
			$newConnections = $this->addMachineToConnections($machineIndex, $connections);
			$this->findCheapestMachineSet($newUsedMachines, $newRemainingMachines, $newConnections, $newCost);
		}
	}
	
	public function solve() {
		$emptyMachineSet = array();//array_fill(0, $this->numChemicals, 0);
		$allMachineSet = array_keys($this->machines);//array_fill(0, $this->numChemicals, 1);
		$emptyConnections = array_fill_keys(array_keys($this->chemicals), $this->chemicals);
		$this->findCheapestMachineSet($emptyMachineSet, $allMachineSet, $emptyConnections, 0);
	}
	
	public function output() {
		if (!$this->bestCost) {
			die("not solvable\n");
		}
		print $this->bestCost . "\n";
		$usedMachines = array();
		foreach ($this->bestMachines as $machineIndex) {
			$usedMachines[] = str_replace("M", "", $this->machines[$machineIndex]["machine"]);
		}
		print implode(" ", $usedMachines) . "\n";
	}
}

$graph = Graph::readMachines($argv[1]);
$graph->preProcess();
$before =time();
$graph->solve();
print "Time: " . (time() - $before) . "\n";
$graph->output();