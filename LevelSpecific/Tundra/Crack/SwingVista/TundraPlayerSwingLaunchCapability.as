class UTundraPlayerSwingLaunchCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(n"TundraSwing");
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default TickGroup = EHazeTickGroup::Movement;

	UTundraPlayerSwingComponent SwingComp;
	UHazeMovementComponent MoveComp;
	USweepingMovementData MoveData;

	bool bSlowDown = false;

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
		if(!SwingComp.PendingImpulse.IsSet())
			return false;

		if(!MoveComp.HasGroundContact())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasGroundContact())
			return true;

		if(SwingComp.bFalling)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(!HasControl())
			Player.SetActorTimeDilation(0.8, this);

		bSlowDown = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		SwingComp.PendingImpulse.Reset();

		Player.ClearActorTimeDilation(this);

		if(SwingComp.bIsActive && !HasControl())
			SwingComp.ApplyLaunchOffset(MoveComp.GetCrumbSyncedPosition().WorldLocation, Player.ActorLocation);

		Player.SetActorLocation(MoveComp.GetCrumbSyncedPosition().WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!MoveComp.PrepareMove(MoveData))
			return;

		// if(!HasControl())
		// {
		// 	if(!bSlowDown && ActiveDuration > 0.5 && MoveComp.VerticalVelocity.Z < 800)
		// 	{
		// 		Player.SetActorTimeDilation(0.5, this);
		// 		bSlowDown = true;
		// 	}
		// }

		MoveData.AddPendingImpulses();
		MoveData.AddGravityAcceleration();
		MoveData.AddOwnerVerticalVelocity();

		MoveComp.ApplyMove(MoveData);

		if (Player.Mesh.CanRequestLocomotion())
			Player.Mesh.RequestLocomotion(n"AirMovement", this);
	}
};