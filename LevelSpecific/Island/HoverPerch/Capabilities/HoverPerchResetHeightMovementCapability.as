class UHoverPerchResetHeightMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default DebugCategory = n"Movement";

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	UHazeMovementComponent MoveComp;
	UPlayerMovementComponent PlayerMoveComp;
	USweepingMovementData Movement;

	AHoverPerchActor PerchActor;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSweepingMovementData();

		PerchActor = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
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
				PerchActor.ApplyHeightResetMovement(Movement, DeltaTime);
			}
			else
			{
				Movement.ApplyCrumbSyncedAirMovement();
			}

			MoveComp.ApplyMove(Movement);
		}
	}
}