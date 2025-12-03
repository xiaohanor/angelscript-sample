class UTazerBotAirMovementCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::LastMovement;

	default CapabilityTags.Add(PrisonTags::Prison);

	ATazerBot TazerBot;

	UHazeMovementComponent MovementComponent;
	USteppingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		TazerBot = Cast<ATazerBot>(Owner);
		MovementComponent = TazerBot.MovementComponent;
		MoveData = MovementComponent.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!TazerBot.IsHacked())
			return false;

		if (TazerBot.bDestroyed)
			return false;

		if (MovementComponent.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!TazerBot.IsHacked())
			return true;

		if (TazerBot.bDestroyed)
			return true;

		if (MovementComponent.HasMovedThisFrame())
			return true;

		return false;
	}

	// Eman TODO: Add extra juicy stuff like camera shake, player input and mesh rotation
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (MovementComponent.PrepareMove(MoveData))
		{
			MoveData.AddOwnerVerticalVelocity();
			MoveData.AddGravityAcceleration();

			FVector HorizontalVelocity = MovementComponent.HorizontalVelocity;
			FVector HorizontalDrag = -MovementComponent.HorizontalVelocity * DeltaTime;

			HorizontalVelocity += HorizontalDrag;
			MoveData.AddHorizontalVelocity(HorizontalVelocity);

			MovementComponent.ApplyMove(MoveData);
		}
	}
}