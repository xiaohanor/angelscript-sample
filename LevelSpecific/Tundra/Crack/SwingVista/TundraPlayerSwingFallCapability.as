class UTundraPlayerSwingFallCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"TundraSwing");
	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;
	default TickGroup = EHazeTickGroup::Movement;

	UTundraPlayerSwingComponent SwingComp;
	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SwingComp = UTundraPlayerSwingComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MoveData = MoveComp.SetupSweepingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!SwingComp.bIsActive)
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		if(MoveComp.HasGroundContact())
			return false;

		if(MoveComp.VerticalVelocity.Z > 0)
			return false;

		if(Time::GetGameTimeSince(SwingComp.LastLaunchTime) < 0.5)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!SwingComp.bIsActive)
			return true;

		if(MoveComp.HasMovedThisFrame())
			return true;

		if(MoveComp.HasGroundContact())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		SwingComp.bFalling = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingComp.bFalling = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		if(HasControl())
		{
			MoveData.AddGravityAcceleration();
			MoveData.AddOwnerVerticalVelocity();
		}
		else
		{
			MoveData.ApplyCrumbSyncedAirMovement();
			SwingComp.UpdateLaunchedOffset(DeltaTime);
		}

		MoveComp.ApplyMove(MoveData);

		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"AirMovement", this);
	}
};