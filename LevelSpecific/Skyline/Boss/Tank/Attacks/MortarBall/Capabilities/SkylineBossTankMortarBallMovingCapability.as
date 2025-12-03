struct FSkylineBossTankMortarBallMovingDeactivateParams
{
	bool bTimedOut = false;
};

class USkylineBossTankMortarBallMovingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	ASkylineBossTankMortarBall MortarBall;
	UHazeMovementComponent MoveComp;
	USimpleMovementData MoveData;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MortarBall = Cast<ASkylineBossTankMortarBall>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		MoveData = MoveComp.SetupSimpleMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FSkylineBossTankMortarBallMovingDeactivateParams& Params) const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(ActiveDuration > MortarBall.LaunchTrajectory.GetTotalTime() + 5)
		{
			// Timed out
			Params.bTimedOut = true;
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FSkylineBossTankMortarBallMovingDeactivateParams Params)
	{
		if(Params.bTimedOut)
			MortarBall.DestroyActor();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!MoveComp.PrepareMove(MoveData))
			return;

		const FVector Location = MortarBall.LaunchTrajectory.GetLocation(ActiveDuration);
		const FVector Velocity = MortarBall.LaunchTrajectory.GetVelocity(ActiveDuration);

		MoveData.AddDeltaFromMoveToPositionWithCustomVelocity(Location, Velocity);
		MoveData.SetRotation(Velocity.ToOrientationQuat());

		MoveComp.ApplyMove(MoveData);
	}
};