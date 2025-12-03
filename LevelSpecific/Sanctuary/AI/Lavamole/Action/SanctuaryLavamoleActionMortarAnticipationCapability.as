struct FSanctuaryLavamoleActionMortarAnticipationData
{
	float Duration;
}

class USanctuaryLavamoleActionMortarAnticipationCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionMortarAnticipationData Params;
	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);
	UBasicAIProjectileLauncherComponent ProjectileLauncher;
	USanctuaryLavamoleSettings Settings;

	FHazeAcceleratedFloat AccScale;
	AAISanctuaryLavamole Mole;

	const float TinyScale = 0.001;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Mole = Cast<AAISanctuaryLavamole>(Owner);
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		ProjectileLauncher = Mole.MortarLauncher;
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionMortarAnticipationData Parameters)
	{
		Params = Parameters;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Mole.Bite1Comp.IsBitten())
			return true;
		if (ActiveDuration > Params.Duration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bool bAnticipateAnimation = true;
		if (Mole.bIsAggressive && Mole.AnimationMode == ESanctuaryLavamoleAnimation::Shoot)
			bAnticipateAnimation = false;
		
		if (bAnticipateAnimation)
			Mole.AnimationMode = ESanctuaryLavamoleAnimation::AnticipateShoot;

		Mole.PrimedMortar = ProjectileLauncher.Prime();
		Mole.PrimedMortar.bIsLaunched = false;
		Cast<ASanctuaryLavamoleMortarProjectile>(Mole.PrimedMortar.Owner).Owner = Owner;
		Mole.PrimedMortar.Owner.SetActorScale3D(FVector::OneVector * TinyScale);
		AccScale.Value = TinyScale;
		USanctuaryLavamoleEventHandler::Trigger_OnMortarTelegraph(Owner, FSanctuaryLavamoleOnMortarTelegraphEventData(ProjectileLauncher.LaunchLocation));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Mole.PrimedMortar.Owner.SetActorScale3D(FVector::OneVector);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AccScale.SpringTo(1.0, 200.0, 0.2, DeltaTime);
		FVector Scale = FVector::OneVector * Math::Max(TinyScale, AccScale.Value);
		Mole.PrimedMortar.Owner.SetActorScale3D(Scale);
	}
}
