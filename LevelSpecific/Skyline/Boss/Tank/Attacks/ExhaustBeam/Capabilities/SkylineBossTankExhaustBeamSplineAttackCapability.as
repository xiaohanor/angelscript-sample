class USkylineBossTankExhaustBeamSplineAttackCapability : USkylineBossTankChildCapability
{
//	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	USkylineBossTankExhaustBeamComponent ExhaustBeamComponent;

	FHazeAcceleratedFloat Speed;
	float AccelerationDuration = 4.0;
	float RotationSpeed = 100.0;
	float Duration = 6.0;

	bool bSpinning = false;
	float CurrentRotationSpeed = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		
		ExhaustBeamComponent = USkylineBossTankExhaustBeamComponent::Get(BossTank);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ActiveDuration > (
			ExhaustBeamComponent.ActivationTime + 
			(AccelerationDuration * 2.0) + 
			Duration)
			)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		BossTank.OnHeroAttack.Broadcast();

		ExhaustBeamComponent.ActivateExhaustSpline();
//		USkylineBossTankEventHandler::Trigger_OnExhaustStart(BossTank);

		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankWeakPoint, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		FSkylineBossTankLight LightSettings;
		LightSettings.Color = FLinearColor(1.0, 0.0, 0.0) * 40.0;
		LightSettings.BlendTime = 1.0;
		LightSettings.Freq = 15.0;
		LightSettings.FreqAlpha = 1.0;
		BossTank.LightComp.ApplyLightSettings(LightSettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankWeakPoint, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		bSpinning = false;
		USkylineBossTankEventHandler::Trigger_OnSpinningEnd(BossTank);

		BossTank.LightComp.ClearLightSettings(this);

		for (auto Player : Game::Players)
			BossTank.GetBikeFromTarget(Player).ClearSettingsByInstigator(this);

		ExhaustBeamComponent.DeactivateExhaustSpline();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ActiveDuration > ExhaustBeamComponent.ActivationTime)
		{			
			ExhaustBeamComponent.AddExhaustBeamPoint();

			BossTank.SpinningAlpha = (ActiveDuration - ExhaustBeamComponent.ActivationTime) / AccelerationDuration;
		
			if (!bSpinning)
			{
				bSpinning = true;
				USkylineBossTankEventHandler::Trigger_OnSpinningStart(BossTank);
			}
		}

		if (ActiveDuration > ExhaustBeamComponent.ActivationTime + AccelerationDuration + Duration)
		{
			if (ExhaustBeamComponent.bActivated)
			{
				USkylineBossTankEventHandler::Trigger_OnExhaustEnd(BossTank);
			}

			BossTank.SpinningAlpha = 1.0 - ((ActiveDuration - ExhaustBeamComponent.ActivationTime - AccelerationDuration - Duration) / AccelerationDuration);
		}

		CurrentRotationSpeed = Math::Lerp(0.0, RotationSpeed, BossTank.SpinningAlpha);

		BossTank.AddActorLocalRotation(FRotator(0.0, CurrentRotationSpeed, 0.0) * DeltaTime);
	}
}