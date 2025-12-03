class UPinballBossBallLaunchedCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	
	default CapabilityTags.Add(PrisonTags::Prison);
	default CapabilityTags.Add(PrisonTags::Drones);

	default CapabilityTags.Add(Pinball::Tags::Pinball);
	default CapabilityTags.Add(Pinball::Tags::PinballMovement);
	default CapabilityTags.Add(Pinball::Tags::PinballLaunched);

	default DebugCategory = Drone::DebugCategory;

	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	APinballBossBall BossBall;
	UPinballBallComponent BallComp;
	UPinballBossBallLaunchedComponent LaunchedComp;
	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);

		BallComp = UPinballBallComponent::Get(BossBall);
		LaunchedComp = UPinballBossBallLaunchedComponent::Get(BossBall);
		MoveComp = UHazeMovementComponent::Get(BossBall);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		if(!LaunchedComp.WasLaunchedThisFrame())
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
			BossBall.ActorVelocity, 
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

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LaunchedComp.ConsumeLaunch();

		LaunchedComp.bIsLaunched = true;

		BossBall.BlockCapabilities(Pinball::Tags::BlockedWhileLaunched, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchedComp.ResetLaunch();

		BossBall.UnblockCapabilities(Pinball::Tags::BlockedWhileLaunched, this);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(LaunchedComp.WasLaunchedThisFrame())
		{
			LaunchedComp.ConsumeLaunch();
		}

		MoveComp.ClearCurrentGroundedState();
	}
};