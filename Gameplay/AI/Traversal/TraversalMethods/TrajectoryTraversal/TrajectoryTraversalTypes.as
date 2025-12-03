enum EDirectTraversalTrajectoryOption
{
	Destination,
	LaunchDestination,
	Launchpoint,
}

struct FDirectTraversalTrajectoryOptions
{
	TArray<EDirectTraversalTrajectoryOption> Options;	
	int iCurrent;

	FDirectTraversalTrajectoryOptions()
	{
		iCurrent = 0;

		// Default option testing order is this:
		Options.SetNum(3);
		Options[0] = EDirectTraversalTrajectoryOption::Destination;
		Options[1] = EDirectTraversalTrajectoryOption::LaunchDestination;
		Options[2] = EDirectTraversalTrajectoryOption::Launchpoint;
	}

	EDirectTraversalTrajectoryOption ConsumeOption()
	{
		int iOption = iCurrent;
		iCurrent = (iCurrent + 1) % Options.Num();
		return Options[iOption % Options.Num()];
	}
}
