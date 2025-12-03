class UGravityBikeFreeJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::MovementInput);
	default CapabilityTags.Add(GravityBikeFree::Jump::GravityBikeFreeJump);

	default TickGroup = EHazeTickGroup::ActionMovement;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeJumpComponent JumpComp;
	UGravityBikeFreeHoverComponent HoverComp;

	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		JumpComp = UGravityBikeFreeJumpComponent::Get(GravityBike);
		HoverComp = UGravityBikeFreeHoverComponent::Get(GravityBike);

		Player = GravityBike.GetDriver();
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
		const FVector JumpDirection = JumpComp.Settings.bJumpTowardsGlobalUp ? FVector::UpVector : GravityBike.GetAcceleratedUp();

		FVector JumpImpulse;
		if(JumpComp.Settings.bCanApplyJumpImpulse && GetImpulseToApply(JumpImpulse))
		{
			GravityBike.AddMovementImpulse(JumpImpulse);

#if !RELEASE
			TEMPORAL_LOG(this).DirectionalArrow("Jump Impulse", GravityBike.ActorLocation, JumpImpulse);
#endif
		}

		HoverComp.AddPitchImpulse(GravityBike.ActorRightVector * JumpComp.Settings.PitchImpulse);

		FGravityBikeFreeJumpEventData EventData;

		FHazeTraceSettings TraceSettings = Trace::InitFromMovementComponent(GravityBike.MoveComp);
		TraceSettings.UseLine();
		FHitResult GroundHit = TraceSettings.QueryTraceSingle(GravityBike.ActorLocation, GravityBike.ActorLocation - JumpDirection * 100);

		if(GroundHit.IsValidBlockingHit())
		{
			EventData.bHasGroundImpact = true;
			EventData.GroundImpactPoint = GroundHit.ImpactPoint;
			EventData.GroundNormal = GroundHit.ImpactNormal;
		}

		UGravityBikeFreeEventHandler::Trigger_OnJump(GravityBike, EventData);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementJump);
		GravityBike.AnimationData.JumpFrame = Time::FrameNumber;

		GravityBike.IsAirborne.Apply(true, this, EInstigatePriority::High);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GravityBike.IsAirborne.Clear(this);
	}

	/**
	 * False if no impulse should be applied
	 */
	bool GetImpulseToApply(FVector&out ImpulseToApply)
	{
		const FVector JumpDirection = JumpComp.Settings.bJumpTowardsGlobalUp ? FVector::UpVector : GravityBike.GetAcceleratedUp();
		ImpulseToApply = JumpDirection * JumpComp.Settings.JumpImpulse;

		FVector TargetVelocity = GravityBike.ActorVelocity + ImpulseToApply;

		if(JumpComp.Settings.bLimitGlobalUpVelocity)
		{
			FVector VerticalTargetVelocity = TargetVelocity.ProjectOnToNormal(FVector::UpVector);
			const FVector HorizontalTargetVelocity = TargetVelocity - VerticalTargetVelocity;

			VerticalTargetVelocity = VerticalTargetVelocity.GetClampedToMaxSize(JumpComp.Settings.MaxGlobalUpVelocity);
			TargetVelocity = HorizontalTargetVelocity + VerticalTargetVelocity;
		}

		if(JumpComp.Settings.bLimitJumpDirectionVelocity)
		{
			FVector JumpDirectionTargetVelocity = TargetVelocity.ProjectOnToNormal(JumpDirection);
			const FVector HorizontalTargetVelocity = TargetVelocity - JumpDirectionTargetVelocity;

			JumpDirectionTargetVelocity = JumpDirectionTargetVelocity.GetClampedToMaxSize(JumpComp.Settings.MaxJumpDirectionVelocity);
			TargetVelocity = HorizontalTargetVelocity + JumpDirectionTargetVelocity;
		}

		ImpulseToApply = TargetVelocity - GravityBike.ActorVelocity;

		if(!JumpComp.Settings.bAllowJumpImpulseBackwards && ImpulseToApply.DotProduct(GravityBike.ActorVelocity) < 0)
		{
			const FVector ImpulseAlongVelocity = ImpulseToApply.ProjectOnToNormal(GravityBike.ActorVelocity.GetSafeNormal());
			ImpulseToApply -= ImpulseAlongVelocity;
		}

		return !ImpulseToApply.IsNearlyZero();
	}
};