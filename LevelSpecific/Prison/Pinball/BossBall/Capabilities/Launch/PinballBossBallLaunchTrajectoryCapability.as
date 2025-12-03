class UPinballBossBallLaunchTrajectoryCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 90;

	default CapabilityTags.Add(CapabilityTags::Movement);

	APinballBossBall BossBall;
	UPinballBossBallLaunchedComponent LaunchedComp;

	UHazeMovementComponent MoveComp;
	UPinballMagnetDroneMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		BossBall = Cast<APinballBossBall>(Owner);
		LaunchedComp = UPinballBossBallLaunchedComponent::Get(BossBall);

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

		if(!LaunchedComp.bLaunchIsTrajectory)
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

		if(!LaunchedComp.bLaunchIsTrajectory)
			return true;

		if(ActiveDuration > LaunchedComp.LaunchTrajectory.GetTotalTime())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LaunchedComp.ResetLaunchTrajectory();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		FVector TargetLocation = LaunchedComp.LaunchTrajectory.GetLocation(ActiveDuration);
		MoveData.AddDeltaFromMoveTo(TargetLocation);

		MoveComp.ApplyMove(MoveData);
	}
};