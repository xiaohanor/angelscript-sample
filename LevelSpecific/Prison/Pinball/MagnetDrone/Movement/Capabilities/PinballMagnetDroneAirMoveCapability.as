class UPinballMagnetDroneAirMoveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::PinballMovement);

	default CapabilityTags.Add(MagnetDroneTags::BlockedWhileAttached);

	default DebugCategory = Drone::DebugCategory;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 93;

	UMagnetDroneComponent DroneComp;
	UPinballMagnetDroneComponent PinballComp;
	UPinballMagnetDroneLaunchedComponent LaunchedComp;
	UPlayerMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DroneComp = UMagnetDroneComponent::Get(Player);
		PinballComp = UPinballMagnetDroneComponent::Get(Player);
		LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);

		MoveComp = UPlayerMovementComponent::Get(Player);
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
	void OnActivated()
	{
		Player.BlockCapabilities(DroneCommonTags::BaseDroneMovement, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(DroneCommonTags::BaseDroneMovement, this);
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
			MoveComp.MovementInput.Y, 
			PinballComp.MovementSettings, 
			DeltaTime
		);

		MoveData.AddDeltaWithCustomVelocity(Delta, Velocity);
		MoveData.AddPendingImpulses();
		
		if(DroneComp.MovementSettings.bUnstableOnEdges)
			MoveData.ApplyUnstableEdgeDistance(FMovementSettingsValue::MakeValue(0));
	
		MoveComp.ApplyMove(MoveData);
	}
}
