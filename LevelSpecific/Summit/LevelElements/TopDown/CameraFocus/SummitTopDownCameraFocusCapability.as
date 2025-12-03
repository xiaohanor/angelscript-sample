class USummitTopDownCameraFocusCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Input;

	ASummitTopDownCameraFocusActor FocusActor;

	FHazeAcceleratedVector AccLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		FocusActor = Cast<ASummitTopDownCameraFocusActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if(!FocusActor.TopDownIsActive())
		// 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// if(!FocusActor.TopDownIsActive())
		// 	return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FocusActor.SnapToBetweenPlayers();

		if(!FocusActor.bHasBeenActivated)
		{
			for(auto Player : Game::Players)
			{
				FocusActor.RequestComp.StartInitialSheetsAndCapabilities(Player, this);
			}
			FocusActor.bHasBeenActivated = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector TargetLocation;
		for(auto Player : Game::Players)
		{
			TargetLocation += FocusActor.PlayerLocation[Player];
		}
		TargetLocation *= 0.5;

		// Maybe accelerate the vector here
		FocusActor.SetActorLocation(TargetLocation);
	}
};