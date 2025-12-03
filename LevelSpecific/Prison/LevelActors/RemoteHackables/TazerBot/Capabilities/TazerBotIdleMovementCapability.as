class UTazerBotIdleMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;

	ATazerBot TazerBot;
	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
		MovementComponent = UHazeMovementComponent::Get(Owner);
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TazerBot.IsHacked())
			return false;

		if (TazerBot.AttachParentActor != nullptr)
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		if (TazerBot.bDestroyed)
			return false;

		if (TazerBot.bRespawning)
			return false;

		if (TazerBot.bLaunched)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TazerBot.IsHacked())
			return true;

		if (TazerBot.AttachParentActor != nullptr)
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		if (TazerBot.bDestroyed)
			return true;

		if (TazerBot.bRespawning)
			return true;

		if (TazerBot.bLaunched)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TazerBot.AttachParentActor != nullptr)
			return;

		if (MovementComponent.PrepareMove(MoveData))
		{
			if (HasControl())
			{
				MoveData.AddOwnerVerticalVelocity();
				MoveData.AddGravityAcceleration();
			}
			else
			{
				if (MovementComponent.IsOnAnyGround())
					MoveData.ApplyCrumbSyncedGroundMovement();
				else
					MoveData.ApplyCrumbSyncedAirMovement();
			}

			MovementComponent.ApplyMove(MoveData);
		}
	}
}