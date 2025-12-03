struct FGravityBikeSplineAutoSteerVolumeActivateParams
{
	AGravityBikeSplineAutoSteerVolume AutoSteerVolume;
};

class UGravityBikeSplineAutoSteerVolumeCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Local;
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 90;

	AGravityBikeSpline GravityBike;
	UGravityBikeSplineMovementComponent MoveComp;
	UGravityBikeSplineAutoSteerComponent AutoSteerComp;

	AGravityBikeSplineAutoSteerVolume CurrentAutoSteerVolume;
	bool bHasBeenAirborne = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeSpline>(Owner);
		MoveComp = GravityBike.MoveComp;
		AutoSteerComp = UGravityBikeSplineAutoSteerComponent::Get(GravityBike);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityBikeSplineAutoSteerVolumeActivateParams& Params) const
	{
		if(!HasControl())
			return false;

		if(AutoSteerComp.CurrentAutoSteerVolumes.IsEmpty())
			return false;
		
		AGravityBikeSplineAutoSteerVolume AutoSteerVolume = AutoSteerComp.CurrentAutoSteerVolumes.Last();

		if(AutoSteerVolume.bApplyOnlyWhileAirborne && !GravityBike.IsAirborne.Get())
			return false;

		Params.AutoSteerVolume = AutoSteerVolume;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CurrentAutoSteerVolume.bClearOnlyWhenGrounded)
		{
			if(!AutoSteerComp.CurrentAutoSteerVolumes.Contains(CurrentAutoSteerVolume))
			{
				if(bHasBeenAirborne && MoveComp.IsOnAnyGround())
					return true;
			}
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityBikeSplineAutoSteerVolumeActivateParams Params)
	{
		CurrentAutoSteerVolume = Params.AutoSteerVolume;

		FGravityBikeSplineAutoSteerSettings Settings;
		Settings.AutoSteerTargetRotation = CurrentAutoSteerVolume.AutoSteerDirectionComp.WorldRotation;
		Settings.AutoSteerInfluence = CurrentAutoSteerVolume.AutoSteerInfluence;
		Settings.AutoSteerThresholdDegrees = CurrentAutoSteerVolume.AutoSteerThresholdDegrees;
		AutoSteerComp.Settings.Apply(Settings, this);

		bHasBeenAirborne = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AutoSteerComp.Settings.Clear(this);
		
		CurrentAutoSteerVolume = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(GravityBike.IsAirborne.Get())
		{
			bHasBeenAirborne = true;
		}
	}
};