class UPinballBossBallAirMoveCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 93;
	
	default CapabilityTags.Add(CapabilityTags::Movement);

	APinballBossBall BossBall;
	UPinballBossBallLaunchedComponent LaunchedComp;
	UHazeMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData; 

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);
		LaunchedComp = UPinballBossBallLaunchedComponent::Get(Owner);
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

		if(!MoveComp.IsInAir())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(!MoveComp.IsInAir())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{	
		if(!MoveComp.PrepareMove(MoveData))
			return;

		FVector Delta;
		FVector Velocity = MoveComp.Velocity;
		Pinball::AirMoveSimulation::Tick(
			Delta,
			Velocity,
			LaunchedComp.bIsLaunched,
			0,
			BossBall.MovementSettings,
			DeltaTime
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);

		// Also add world impulses
		MoveData.AddPendingImpulses();

		MoveComp.ApplyMove(MoveData);
	}
};