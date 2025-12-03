class UGravityBikeFreeKartDriftJumpCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeDrift);

	default TickGroup = EHazeTickGroup::ActionMovement;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeKartDriftComponent DriftComp;
	UHazeMovementComponent MoveComp;

	bool bForceAirborne = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		DriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);
		MoveComp = UHazeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DriftComp.Settings.bDoLilJump)
			return false;
		
		if(!GravityBike.Input.bDrift)
			return false;

		if(MoveComp.IsInAir())
			return false;

		if(DriftComp.IsDrifting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MoveComp.IsOnAnyGround())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DriftComp.bIsDriftJumping = true;

		GravityBike.AddMovementImpulse(FVector::UpVector * DriftComp.Settings.KartDriftJumpVerticalImpulse);
		GravityBike.IsAirborne.Apply(false, this, EInstigatePriority::High);
		bForceAirborne = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DriftComp.bIsDriftJumping = false;

		if(bForceAirborne)
		{
			GravityBike.IsAirborne.Clear(this);
			bForceAirborne = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bForceAirborne && ActiveDuration > DriftComp.Settings.ForceAirborneTime)
		{
			GravityBike.IsAirborne.Clear(this);
			bForceAirborne = false;
		}
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		TemporalLog.Value("bForceAirborne", bForceAirborne);
	}
#endif
};