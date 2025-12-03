class UPinballBossBallMoveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 93;

	default CapabilityTags.Add(CapabilityTags::Movement);

	APinballBossBall BossBall;
	UHazeMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupMovementData(UPinballMagnetDroneMovementData);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		FVector Delta;
		FVector Velocity = MoveComp.Velocity;
		Pinball::GroundMoveSimulation::Tick(
			Delta,
			Velocity,
			0,
			MoveComp.IsOnWalkableGround(),
			MoveComp.GroundContact.Normal,
			Pinball::GetWorldUp(),
			BossBall.MovementSettings,
			DeltaTime
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();

		MoveComp.ApplyMove(MoveData);
	}
};