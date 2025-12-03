class UGravityBikeSplineJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(GravityBikeSpline::Tags::GravityBikeSpline);
	default CapabilityTags.Add(GravityBikeSpline::Jump::GravityBikeSplineJump);

	default TickGroup = EHazeTickGroup::ActionMovement;

	AGravityBikeSpline GravityBike;
	UHazeMovementComponent MoveComp;
	UGravityBikeSplineJumpComponent JumpComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = UHazeMovementComponent::Get(GravityBike);
		JumpComp = UGravityBikeSplineJumpComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!JumpComp.Settings.bAllowJumping)
			return false;

		if(!WasActionStartedDuringTime(ActionNames::MovementJump, 0.2))
			return false;

		if(GravityBike.IsAirborne.Get())
			return false;

		// Something else has jumped
		if(JumpComp.IsJumping())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GravityBike.MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GravityBike.GetDriver().ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);

		FVector JumpImpulse;
		if(JumpComp.Settings.bCanApplyJumpImpulse && JumpComp.GetImpulseToApply(JumpImpulse))
		{
			MoveComp.AddPendingImpulse(JumpImpulse);

#if !RELEASE
			TEMPORAL_LOG(this).DirectionalArrow("Jump Impulse", GravityBike.ActorLocation, JumpImpulse);
#endif
		}

		JumpComp.StartJumping(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		JumpComp.StopJumping(this);
	}
};