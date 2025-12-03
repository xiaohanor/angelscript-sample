struct FSanctuaryLavamoleActionWhackedData
{
}

class USanctuaryLavamoleActionWhackedCapability : UHazeActionQueueCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	FSanctuaryLavamoleActionWhackedData Params;

	default CapabilityTags.Add(LavamoleTags::LavaMole);
	default CapabilityTags.Add(LavamoleTags::Action);

	AAISanctuaryLavamole Lavamole;
	USanctuaryLavamoleSettings Settings;

	FHazeAcceleratedFloat AccSquishy;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USanctuaryLavamoleSettings::GetSettings(Owner);
		Lavamole = Cast<AAISanctuaryLavamole>(Owner);
		AccSquishy.SnapTo(1.0);

		SanctuaryCentipedeDevToggles::Mole::MoleOneWhack.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void OnBecomeFrontOfQueue(FSanctuaryLavamoleActionWhackedData Parameters)
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
		if (ActiveDuration > Settings.WhackSquishyDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Lavamole.AnimationMode = ESanctuaryLavamoleAnimation::TakeDamage;
		Lavamole.RemoveUnlaunchedMortar();
		USanctuaryLavamoleEventHandler::Trigger_OnWhacked(Owner);
		if (Lavamole.WhackForceFeedbackEffect != nullptr)
		{
			if (Lavamole.Bite1Comp != nullptr && Lavamole.Bite1Comp.Biter != nullptr)
				Lavamole.Bite1Comp.Biter.PlayForceFeedback(Lavamole.WhackForceFeedbackEffect, false, false, this, 1.0);

			if (Lavamole.Bite2Comp != nullptr && Lavamole.Bite2Comp.Biter != nullptr)
				Lavamole.Bite2Comp.Biter.PlayForceFeedback(Lavamole.WhackForceFeedbackEffect, false, false, this, 1.0);
		}
		// if (Lavamole.WhackedVFX != nullptr)
		// 	Niagara::SpawnOneShotNiagaraSystemAtLocation(Lavamole.WhackedVFX, Lavamole.ActorLocation, Lavamole.ActorRotation);

		if (SanctuaryCentipedeDevToggles::Mole::MoleOneWhack.IsEnabled())
			Lavamole.bIsWhacky = true;

		Lavamole.WhackedTimes++;
		float Damage = 1.0 / Math::TruncToFloat(Lavamole.WhackTimesDeath +1);
		Lavamole.HealthComp.TakeDamage(Damage, EDamageType::Default, Lavamole);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Lavamole.MeshOffsetComponent.SetWorldScale3D(FVector::OneVector);
		Lavamole.bIsWhacky = false;
		if (Lavamole.AnimationMode == ESanctuaryLavamoleAnimation::TakeDamage)
			Lavamole.AnimationMode = ESanctuaryLavamoleAnimation::IdleAbove;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// squishy!
		// FVector Scaling = FVector::OneVector;
		// float ScaleAlpha = Math::Clamp(ActiveDuration / Settings.WhackSquishyDuration, 0.0, 1.0);
		// AccSquishy.AccelerateTo(SanctuaryLavamoleWhackedScaleCurve.GetFloatValue(ScaleAlpha), 0.1, DeltaTime);
		// Scaling.Z = AccSquishy.Value;

		// // Debug::DrawDebugString(Lavamole.ActorLocation, "Scaling " + ScalingFraction);
		// if (Scaling.Z > 1.0)
		// {
		// 	float ScalingValue = Math::Clamp(1 + (1 - Scaling.Z) * 0.5, 0.05, 50.0);

		// 	Scaling.X = ScalingValue;
		// 	Scaling.Y = ScalingValue;
		// }
		// Lavamole.MeshOffsetComponent.SetWorldScale3D(Scaling);
	}
};