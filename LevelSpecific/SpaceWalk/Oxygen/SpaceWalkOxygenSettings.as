class USpaceWalkOxygenSettings : UHazeComposableSettings
{
	// How long a full oxygen tank for the players lasts before game over
	UPROPERTY()
	float OxygenDuration = 85.0;

	// Duration of the full timing bar 
	UPROPERTY()
	float OxygenTimingCycleDuration = 1.5;

	// Success window at the end of the bar, percentage of the cycle duration
	UPROPERTY()
	float OxygenTimingSuccessPct = 0.32;

	// How much the success window shrinks for every pump
	UPROPERTY()
	float OxygenTimingSuccessShrinkPerPump = 0.01;

	// Randomize the position of the success window within this much of the end of the bar
	UPROPERTY()
	float OxygenTimingRandomizationWindow = 0.25;

	// Required pumps before the oxygen interaction is completed
	UPROPERTY()
	int RequiredOxygenPumps = 8;

	// How much faster does the oxygen interaction get each time a pump is completed
	UPROPERTY()
	float SpeedUpPerPumpCycle = 0.09;
}

namespace SpacewalkOxygen
{
	const FHazeDevToggleBool DevToggle_InfiniteOxygen;
}