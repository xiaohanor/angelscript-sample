class UPinballMagnetDroneLaunchedCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::PinballMovement);
	default CapabilityTags.Add(Pinball::Tags::PinballLaunched);

	default CapabilityTags.Add(Pinball::Tags::BlockedWhileInRail);

	default DebugCategory = Drone::DebugCategory;

	// Run before Movement, so that us changing the velocity is considered this tick
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UPinballBallComponent BallComp;
	UPinballMagnetDroneLaunchedComponent LaunchedComp;
	UHazeMovementComponent MoveComp;

	UMagnetDroneComponent DroneComp;
	UMagnetDroneAttachedComponent AttachedComp;
	bool bWasMagneticallyAttached = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BallComp = UPinballBallComponent::Get(Player);
		LaunchedComp = UPinballMagnetDroneLaunchedComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);

		DroneComp = UMagnetDroneComponent::Get(Player);
		AttachedComp = UMagnetDroneAttachedComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!LaunchedComp.WasLaunchedThisFrame())
			return false;

		if(Player.IsPlayerDead())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(LaunchedComp.WasLaunchedThisFrame())
			return false;

		if(!LaunchedComp.WasLaunched())
			return true;

		if(!Pinball::IsLaunching(
			Owner.ActorVelocity, 
			LaunchedComp.GetLaunchDirection(), 
			LaunchedComp.LaunchData.LaunchedBy,
			LaunchedComp.LaunchedTime, 
			Time::GameTimeSeconds)
		)
		{
			return true;
		}

		if(Time::GetGameTimeSince(LaunchedComp.LaunchedTime) > 0.1)
		{
			if(MoveComp.HasAnyValidBlockingImpacts())
				return true;
		}

		if(Player.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaunchedComp.ConsumeLaunch();
		
		LaunchedComp.bIsLaunched = true;

		if(AttachedComp.IsAttached())
		{
			AttachedComp.Detach(n"Pinball_Launched");
			bWasMagneticallyAttached = true;

			Player.BlockCapabilities(MagnetDroneTags::MagnetDroneSurfaceMovement, this);
			Player.BlockCapabilities(MagnetDroneTags::MagnetDroneAttraction, this);
			Player.BlockCapabilities(MagnetDroneTags::MagnetDroneAim, this);
		}
		
		Player.BlockCapabilities(Pinball::Tags::BlockedWhileLaunched, this);
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bWasMagneticallyAttached)
		{
			bWasMagneticallyAttached = false;
			
			Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneSurfaceMovement, this);
			Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneAttraction, this);
			Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneAim, this);
		}

		LaunchedComp.ResetLaunch();

		Player.UnblockCapabilities(Pinball::Tags::BlockedWhileLaunched, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LaunchedComp.HasLaunchToConsume())
			LaunchedComp.ConsumeLaunch();

		MoveComp.ClearCurrentGroundedState();
	}
}