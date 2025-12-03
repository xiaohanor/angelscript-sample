class UGravityBikeFreeBoostCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFree);
	default CapabilityTags.Add(GravityBikeFree::Tags::GravityBikeFreeBoost);

	default TickGroup = EHazeTickGroup::Movement;
	default TickGroupOrder = 100;

	AGravityBikeFree GravityBike;
	UGravityBikeFreeBoostComponent BoostComp;
	UGravityBikeFreeMovementComponent MoveComp;
	UGravityBikeFreeMovementData Movement;

	AHazePlayerCharacter Player;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GravityBike = Cast<AGravityBikeFree>(Owner);
		BoostComp = UGravityBikeFreeBoostComponent::Get(GravityBike);
		MoveComp = UGravityBikeFreeMovementComponent::Get(GravityBike);
		Movement = MoveComp.SetupMovementData(UGravityBikeFreeMovementData);

		Player = GravityBike.GetDriver();
		CameraSettings = UCameraSettings::GetSettings(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!BoostComp.ShouldBoost())
			return false;

		// Don't boost while drifting
		if(GravityBike.IsDrifting())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!BoostComp.ShouldBoost())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BoostComp.bIsBoosting = true;
		BoostComp.StartBoostTime = Time::GameTimeSeconds;

		UGravityBikeFreeEventHandler::Trigger_OnBoostStart(GravityBike);
		GravityBike.AnimationData.bIsBoosting = true;
		CameraSettings.FOV.ApplyAsAdditive(BoostComp.Settings.BoostFOVAdditive, this, 0.5);

		if(BoostComp.Settings.ApplyMode == EGravityBikeFreeBoostApplyMode::Settings)
		{
			GravityBike.ApplySettings(GravityBikeFreeSettingsBoost, this);
			UGravityBikeFreeSettings::SetMaxSpeed(GravityBike, GravityBikeFreeSettingsBoost.MaxSpeed * BoostComp.Settings.BoostScale, this);
			UGravityBikeFreeSettings::SetAcceleration(GravityBike, GravityBikeFreeSettingsBoost.Acceleration * BoostComp.Settings.BoostScale, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BoostComp.bIsBoosting = false;

		UGravityBikeFreeEventHandler::Trigger_OnBoostEnd(GravityBike);
		CameraSettings.FOV.Clear(this, 1);

		GravityBike.AnimationData.bIsBoosting = false;

		if(BoostComp.Settings.ApplyMode == EGravityBikeFreeBoostApplyMode::Settings)
			GravityBike.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BoostComp.BoostFOVCurve == nullptr)
			return;

		if(HasControl() && BoostComp.AppliedBoostThisFrame())
		{
			CrumbOnBoostRefill();
		}

		float BoostAlpha = BoostComp.GetBoostFactor();
		float FOVFactor = BoostComp.BoostFOVCurve.GetFloatValue(ActiveDuration / BoostComp.Settings.MaxBoostTime);
		const float FOVAlpha = BoostAlpha * FOVFactor;
		CameraSettings.FOV.SetManualFraction(FOVAlpha, this);

		GravityBike.AnimationData.BoostAlpha = BoostAlpha;
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnBoostRefill()
	{
		UGravityBikeFreeEventHandler::Trigger_OnBoostRefill(GravityBike);
	}
}