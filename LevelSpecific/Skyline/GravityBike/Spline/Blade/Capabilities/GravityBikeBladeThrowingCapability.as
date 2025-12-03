struct FGravityBikeBladeThrowingActivateParams
{
	AGravityBikeBladeGravityTrigger Trigger;
}

/**
 * We give input to start a throw, and the throwing animation will start
 */
class UGravityBikeBladeThrowingCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBlade);
	default CapabilityTags.Add(GravityBikeBlade::Tags::GravityBikeBladeThrow);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 9; // Before UGravityBikeBladeThrowCapability

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineMovementData MoveData;

	AHazePlayerCharacter BladePlayer;
	UGravityBikeBladePlayerComponent BladeComp;
	UCameraUserComponent CameraUserComp;

	AGravityBikeBladeGravityTrigger TargetTrigger;

	FVector StartVelocity;

	FQuat StartRotation;
	FQuat TargetRotation;

	bool bAppliedCameraSettings = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		MoveData = MoveComp.SetupMovementData(UGravityBikeSplineMovementData);

		BladePlayer = GravityBikeBlade::GetPlayer();
		BladeComp = UGravityBikeBladePlayerComponent::Get(BladePlayer);
		CameraUserComp = UCameraUserComponent::Get(BladePlayer);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeBladeThrowingActivateParams& Params) const
	{
		if(!WasActionStarted(GravityBikeBlade::ChangeGravityInput))
			return false;

		if(MoveComp.HasMovedThisFrame())
			return false;

		// Can only start throw from None or Barrel
		switch(BladeComp.State)
		{
			case EGravityBikeBladeState::None:
				break;

			case EGravityBikeBladeState::Throwing:
				return false;

			case EGravityBikeBladeState::Thrown:
				return false;

			case EGravityBikeBladeState::Grappling:
				return false;

			case EGravityBikeBladeState::Barrel:
				break;
		}

		if(!BladeComp.HasThrowTarget())
			return false;

		Params.Trigger = BladeComp.GetPrimaryGravityTrigger();
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.HasMovedThisFrame())
			return true;

		if(BladeComp.State != EGravityBikeBladeState::Throwing)
			return true;

		if(ActiveDuration > GravityBikeBlade::ThrowingDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeBladeThrowingActivateParams Params)
	{
		TargetTrigger = Params.Trigger;

		BladeComp.OnThrowingAnimationStarted(TargetTrigger);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BladeComp.OnThrowingAnimationFinished();
	}
}