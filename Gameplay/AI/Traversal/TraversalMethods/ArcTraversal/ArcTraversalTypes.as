enum EDirectTraversalArcOption
{
	Destination,
	LaunchDestination,
	LaunchDestinationStraight,
	LaunchpointStraight,
}

struct FDirectTraversalArcOptions
{
	TArray<EDirectTraversalArcOption> Options;	
	int iCurrent;

	FDirectTraversalArcOptions()
	{
		iCurrent = 0;

		// Default option testing order is this:
		Options.SetNum(4);
		Options[0] = EDirectTraversalArcOption::Destination;
		Options[1] = EDirectTraversalArcOption::LaunchDestinationStraight;
		Options[2] = EDirectTraversalArcOption::LaunchDestination;
		Options[3] = EDirectTraversalArcOption::LaunchpointStraight;
	}

	EDirectTraversalArcOption ConsumeOption()
	{
		int iOption = iCurrent;
		iCurrent = (iCurrent + 1) % Options.Num();
		return Options[iOption % Options.Num()];
	}
}
