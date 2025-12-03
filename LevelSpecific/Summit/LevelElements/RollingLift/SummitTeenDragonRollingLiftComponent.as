class USummitTeenDragonRollingLiftComponent : UActorComponent
{
	bool bIsDriver = false;
	ASummitRollingLift CurrentRollingLift;
	//TArray<FVector> CustomImpulses; 

	TOptional<FVector> LaunchLocation;

	// Exposed here so AI can use this
	UHazeSplineComponent CurrentSpline;

	void ExitCurrentRollingLift()
	{
		if(CurrentRollingLift == nullptr)
			return;
		
		CurrentRollingLift.ExitRollingLift();
	}
};
