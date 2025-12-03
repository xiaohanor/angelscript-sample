struct FHayStackDiveActivationParams
{
	FVector StartLocation;
	float StartYaw;
}

class UHayStackDiveCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"HayStackDive");

	default TickGroup = EHazeTickGroup::Gameplay;

	UHayStackPlayerComponent HayStackComp;
	FHayStackDiveActivationParams Params;

	bool bDiveFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		HayStackComp = UHayStackPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHayStackDiveActivationParams& ActivationParams) const
	{
		if (!HayStackComp.bDiving)
			return false;

		ActivationParams.StartLocation = HayStackComp.StartLocation;
		ActivationParams.StartYaw = HayStackComp.StartYaw;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bDiveFinished)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHayStackDiveActivationParams ActivationParams)
	{
		bDiveFinished = false;
		HayStackComp.bDiving = false;
		Params = ActivationParams;

		Player.PlayCameraShake(HayStackComp.DiveCamShake, this);

		FHazeAnimationDelegate AnimFinished;
		AnimFinished.BindUFunction(this, n"DiveAnimFinished");
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Player.IsMio() ? HayStackComp.MioDiveAnim : HayStackComp.ZoeDiveAnim;
		Player.PlayEventAnimation(FHazeAnimationDelegate(), AnimFinished, AnimParams);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);

		SpeedEffect::RequestSpeedEffect(Player, 1.0, this, EInstigatePriority::High);

		Player.SmoothTeleportActor(Params.StartLocation, FRotator(0.0, Params.StartYaw, 0.0), this);

		UCameraSettings::GetSettings(Player).IdealDistance.Apply(720.0, this, 1.0);
	}

	UFUNCTION()
	private void DiveAnimFinished()
	{
		bDiveFinished = true;

		Player.PlayForceFeedback(HayStackComp.LandFF, false, true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.StopCameraShakeByInstigator(this);

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);

		SpeedEffect::ClearSpeedEffect(Player, this);

		UCameraSettings::GetSettings(Player).IdealDistance.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float FFFrequency = 25.0;
		float FFIntensity = 0.3;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity; 
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		Player.SetFrameForceFeedback(FF);
	}
}