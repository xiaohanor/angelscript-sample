class USkylineBossTankExhaustBeamAttackCapability : USkylineBossTankChildCapability
{
//	default CapabilityTags.Add(SkylineBossTankTags::SkylineBossTankAttack);

	USkylineBossTankExhaustBeamComponent ExhaustBeamComponent;

	FHazeAcceleratedFloat Speed;
	float AccelerationDuration = 2.0; //2.0
	float RotationSpeed = 200.0; //100.0
	float Duration = 8.0;

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
/*
		if (BossTank.State != ESkylineBossTankState::Spinning)
			return false;

		if (DeactiveDuration < 5.0)
			return false;
*/
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (BossTank.State != ESkylineBossTankState::Spinning)
//			return true;

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

		ExhaustBeamComponent.ActivateExhaust();
		USkylineBossTankEventHandler::Trigger_OnExhaustStart(BossTank);

//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankWeakPoint, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
//		BossTank.BlockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		FSkylineBossTankLight LightSettings;
		LightSettings.Color = FLinearColor(1.0, 0.0, 0.0) * 40.0;
		LightSettings.BlendTime = 1.0;
		LightSettings.Freq = 15.0;
		LightSettings.FreqAlpha = 1.0;
		BossTank.LightComp.ApplyLightSettings(LightSettings, this);
/*
		FCenterViewForcedTarget CenterViewForcedTarget;
		CenterViewForcedTarget.Instigator = BossTank;
		CenterViewForcedTarget.Priority = EInstigatePriority::Normal;
		CenterViewForcedTarget.Target = BossTank.CenterViewTargetComp;
		CenterViewForcedTarget.Params.bRequireInputToActivate = false;
		CenterViewForcedTarget.Params.bShowTutorial = false;
		CenterViewForcedTarget.Params.bAllowCameraInputToDeactivate = true;
		CenterViewForcedTarget.Params.bAllowCenterViewInputToDeactivate = true;
		CenterViewForcedTarget.Params.bClearOnDeactivate = true;

		for (auto Player : Game::Players)
		{
			Player.ApplyForcedCenterViewTarget(CenterViewForcedTarget);
		}
*/
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChase, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankAttack, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankWeakPoint, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankSpotlight, this);
//		BossTank.UnblockCapabilities(SkylineBossTankTags::SkylineBossTankChangeTarget, this);

		bSpinning = false;
		USkylineBossTankEventHandler::Trigger_OnSpinningEnd(BossTank);

		BossTank.LightComp.ClearLightSettings(this);

//		for (auto Player : Game::Players)
//			Player.ClearForcedCenterViewTarget(BossTank);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector ExhaustBeamImpactLocation = Math::GetLineSegmentSphereIntersectionPoints(ExhaustBeamComponent.WorldLocation, ExhaustBeamComponent.WorldLocation + (ExhaustBeamComponent.ForwardVector * 100000.0), BossTank.ConstraintRadiusOrigin.ActorLocation, 15500.0).MinIntersection;
//		Debug::DrawDebugSphere(RampImpactLocation, 500.0, 12, FLinearColor::Red, 50.0, 0.0);

		BossTank.ExhaustBeamImpact.SetWorldLocationAndRotation(ExhaustBeamImpactLocation, ExhaustBeamComponent.WorldRotation);
		BossTank.ExhaustBeamLength = ExhaustBeamComponent.WorldLocation.Distance(BossTank.ExhaustBeamImpact.WorldLocation);

		if (ActiveDuration > ExhaustBeamComponent.ActivationTime)
		{
			BossTank.SpinningAlpha = Math::Min(1.0, (ActiveDuration - ExhaustBeamComponent.ActivationTime) / AccelerationDuration);
		
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
				ExhaustBeamComponent.DeactivateExhaust();
				USkylineBossTankEventHandler::Trigger_OnExhaustEnd(BossTank);
			}

			BossTank.SpinningAlpha = 1.0 - ((ActiveDuration - ExhaustBeamComponent.ActivationTime - AccelerationDuration - Duration) / AccelerationDuration);
		}

		CurrentRotationSpeed = Math::Lerp(0.0, RotationSpeed, BossTank.SpinningAlpha);

//		Speed.AccelerateToWithStop((ActiveDuration < ExhaustBeamComponent.ActivationTime + AccelerationDuration + Duration ? RotationSpeed : 0.0), AccelerationDuration, DeltaTime, 0.01);
//		BossTank.AddActorLocalRotation(FRotator(0.0, Speed.Value, 0.0) * DeltaTime);
		BossTank.AddActorLocalRotation(FRotator(0.0, CurrentRotationSpeed, 0.0) * DeltaTime);

		PrintToScreen("SpinSpeed: " + CurrentRotationSpeed + "BossTank.SpinningAlpha: "+ BossTank.SpinningAlpha, 0.0, FLinearColor::Green);
	}
}