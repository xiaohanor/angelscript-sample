class UTundraWalkingStickRiseMovementCapability : UTundraWalkingStickBaseCapability
{
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 1;
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	float StartZLoc;
	float TargetZLoc;
	bool bDone = false;
	bool bBlendingOut = false;
	bool bInAdditionalActiveDuration = false;

	const float RiseDuration = 4.36;
	const float AdditionalActiveDuration = 2.3;
	//const float RiseDuration = 7.65;
	//const float AdditionalActiveDuration = 0.01;

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(WalkingStick.CurrentState != ETundraWalkingStickState::Rising)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(bDone)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bDone = false;
		bInAdditionalActiveDuration = false;
		StartZLoc = WalkingStick.ActorLocation.Z;
		TargetZLoc = StartZLoc + WalkingStick.RootRiseHeightOffset;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		WalkingStick.OnRisingFinalExit();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Alpha = ActiveDuration / RiseDuration;
		if(Alpha >= 1.0 && !bInAdditionalActiveDuration)
		{
			Alpha = 1.0;
			WalkingStick.ChangeState(ETundraWalkingStickState::Walking);
		}

		if((ActiveDuration - RiseDuration) / AdditionalActiveDuration >= 1.0)
		{
			bDone = true;
		}

		if(!bInAdditionalActiveDuration)
		{
			float CurveAlpha = WalkingStick.RiseInterpolation.GetFloatValue(Alpha);
			float CurrentZValue = Math::Lerp(StartZLoc, TargetZLoc, CurveAlpha);

			WalkingStick.ActorLocation = FVector(WalkingStick.ActorLocation.X, WalkingStick.ActorLocation.Y, CurrentZValue);

			if(Alpha == 1.0)
				bInAdditionalActiveDuration = true;
		}

		if(WalkingStick.Mesh.CanRequestLocomotion())
		{
			WalkingStick.Mesh.RequestLocomotion(n"WalkingStickRise", this);
		}
	}
}