class UTundra_SimonSaysMonkeyIdleCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Movement;

	ATundra_SimonSaysMonkey Monkey;
	UTundra_SimonSaysMonkeySettings Settings;
	UHazeMovementComponent MoveComp;
	UTeleportingMovementData Movement;
	ATundra_SimonSaysManager Manager;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Monkey = Cast<ATundra_SimonSaysMonkey>(Owner);
		Settings = UTundra_SimonSaysMonkeySettings::GetSettings(Owner);
		Manager = TundraSimonSays::GetManager();
		MoveComp = Monkey.MoveComp;
		Movement = MoveComp.SetupTeleportingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(MoveComp.PrepareMove(Movement))
		{
			if(HasControl())
			{
				Movement.InterpRotationTo(Monkey.OriginalRotation.Quaternion(), Settings.TurnRate);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
}