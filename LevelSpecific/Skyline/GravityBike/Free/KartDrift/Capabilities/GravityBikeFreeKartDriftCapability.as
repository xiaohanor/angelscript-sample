struct FGravityBikeFreeKartDriftActivateParams
{
	bool bDriftLeft = false;
};

struct FGravityBikeFreeKartDriftDeactivateParams
{
	float BoostDuration = -1;
};

class UGravityBikeFreeKartDriftCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeDrift);

	default TickGroup = EHazeTickGroup::BeforeMovement;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeKartDriftComponent DriftComp;
	UGravityBikeFreeBoostComponent BoostComp;
	UGravityBikeFreeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		DriftComp = UGravityBikeFreeKartDriftComponent::Get(GravityBike);
		BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeFreeKartDriftActivateParams& Params) const
	{
		if(!GravityBike.Input.bDrift)
			return false;

		// Check if we landed
		if(DriftComp.Settings.bDoLilJump)
		{
			const bool bLandedThisFrame = MoveComp.HasGroundContact() && !MoveComp.PreviousHadGroundContact();
			if(!bLandedThisFrame)
				return false;
		}
		else
		{
			if(!MoveComp.HasGroundContact())
				return false;
		}

		// Not steering
		if(Math::Abs(GravityBike.Input.Steering) < 0.1)
			return false;

		Params.bDriftLeft = GravityBike.Input.Steering < 0;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityBikeFreeKartDriftDeactivateParams& Params) const
	{
		if(GravityBike.AlignedWithWallThisOrLastFrame())
		{
			return true;
		}
		
		if(!GravityBike.Input.bDrift)
		{
			// Natural deactivation

			if(GravityBike.Input.Throttle > 0.5)
				Params.BoostDuration = GetBoostDuration();
			
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeFreeKartDriftActivateParams Params)
	{
		DriftComp.StartDrifting(Params.bDriftLeft);

		UGravityBikeFreeSettings::SetMinimumSpeed(GravityBike, DriftComp.Settings.MinSpeed, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityBikeFreeKartDriftDeactivateParams Params)
	{
		DriftComp.StopDrifting();

		//GravityBike.Driver.ConsumeButtonInputsRelatedTo(GravityBikeFree::Input::DriftAction);

		if(DriftComp.Settings.bApplyBoost && Params.BoostDuration > 0)
		{
			BoostComp.SetBoostUntilTime(Time::GameTimeSeconds + Params.BoostDuration);
		}

		UGravityBikeFreeSettings::ClearMinimumSpeed(GravityBike, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	float GetBoostDuration() const
	{
		if(!ensure(IsActive()))
			return -1;

		float BoostAlpha = Math::Saturate(ActiveDuration / DriftComp.Settings.ReachMaxBoostTime);
		BoostAlpha = Math::Pow(BoostAlpha, DriftComp.Settings.ReachMaxBoostExponent);

		return Math::Lerp(
			DriftComp.Settings.MinBoostDuration,
			DriftComp.Settings.MaxBoostDuration,
			BoostAlpha
		);
	}
};