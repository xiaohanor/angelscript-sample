class UPlayerEffortRecoveryAudioCapability : UHazePlayerCapability
{	
	UPlayerEffortAudioComponent EffortComp;

	default DebugCategory = n"Audio";
	default CapabilityTags.Add(n"PlayerMovementEffortAudio");
	default TickGroup = EHazeTickGroup::Audio;
	default TickGroupOrder = 1;


	const float RECOVERY_ACTIVATION_DELAY = 0.5;
	float InterpedExtertion = 0.0;

	UPlayerEffortAudioSettings EffortSettings;
	UPlayerInteractionsComponent InteractionComp;
	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		EffortComp = UPlayerEffortAudioComponent::Get(Player);
		EffortSettings = UPlayerEffortAudioSettings::GetSettings(Player);
		InteractionComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!EffortComp.HasPendingRecoveries())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(EffortComp.HasPendingRecoveries())
			return false;

		// Failsafe to make sure we don't get stuck in exertion, not sure why it can happen...
		if(EffortComp.GetExertion() > 0)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Set curve alpha position based on where we started to recover from
		//EffortComp.RecoveryCurveAlpha = 1 - EffortComp.EffortCurveAlpha;

		InterpedExtertion = EffortComp.GetExertion();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		EffortComp.bIsRecovering = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{				
		EffortComp.bIsRecovering = false;	

		FEffortData& Recovery = EffortComp.GetNextRecoveryData();
		if(Recovery.State != EEffortAudioState::Consumed)
		{
			// This means that we have unhandled exertion, not sure why it happens. Decrement it here to not break things
			InterpedExtertion = Math::FInterpConstantTo(InterpedExtertion, 0.0, DeltaTime, 10);
			EffortComp.EffortCurveAlpha = InterpedExtertion / 100;
			EffortComp.RecoveryCurveAlpha = 1 - EffortComp.EffortCurveAlpha;

			EffortComp.SetRecoveryExertion(InterpedExtertion, DeltaTime);
			return;
		}

		if(CanTickRecovery(Recovery))
		{
			const float IntensityLevelFactor = GetIntensityLevelFactor();

			EffortComp.bIsRecovering = true;
			float FactorDecremetation = (Recovery.RecoveryFactor * DeltaTime) * IntensityLevelFactor * EffortSettings.RecoveryFactor;
			EffortComp.SetRecoveryCurveAlpha(FactorDecremetation);

			float _;
			const float RecoveryCurveValue = EffortComp.GetValueFromCurve(Recovery, _);
			const float EffortCurveValue = EffortComp.GetValueFromCurve(EffortComp.EffortsAsset.EffortCurve, EffortComp.EffortCurveAlpha);
			float CurveValue = Math::Min(RecoveryCurveValue, EffortCurveValue);

			float DecrementedExertion = CurveValue;	

			const float CurrExertion = EffortComp.GetExertion();
			InterpedExtertion = Math::FInterpConstantTo(CurrExertion, DecrementedExertion, DeltaTime, 10.0);
			InterpedExtertion = Math::Min(InterpedExtertion, CurrExertion);

			EffortComp.SetRecoveryExertion(InterpedExtertion, DeltaTime);	

			const float ExertionDelta = CurrExertion - EffortComp.GetExertion();
			Recovery.EffortTotal -= ExertionDelta;

			if(Recovery.EffortTotal <= 0 || EffortComp.GetExertion() == 0)
			{
				EffortComp.ConsumeRecoveredEffort(Recovery);
			}
		}
	}

	private bool CanTickRecovery(const FEffortData& Recovery) const
	{
		if (InteractionComp != nullptr && InteractionComp.ActiveInteraction != nullptr)
			return true;

		// Don't recover if we're airborne and not in a resting climbing state
		if(!Player.IsOnWalkableGround() && !EffortComp.IsInEffortsIdleTag())
			return false;

		// We've already recovered!
		if(Recovery.State == EEffortAudioState::Recovered)
			return false;		

		// Has enough time passed?
		float TimeActive = EffortComp.GetEffortTimeActive();
		if(TimeActive >= 0 && TimeActive < RECOVERY_ACTIVATION_DELAY)
			return false;

		if(EffortComp.bHasValidEffort)
		{
			auto CurrentEffort = EffortComp.GetCurrentEffortData();
			if(CurrentEffort.State == EEffortAudioState::Handling)
			{
				// We're currently tracking a higher intensity effort
				if(int32(Recovery.Intensity) < int32(CurrentEffort.Intensity))
					return false;

				// // Our current effort is higher intensity and ongoing
				// if(CurrentEffort.Intensity >= Recovery.Intensity)
				// {
				// 	if(CurrentEffort.PushType == EEffortAudioPushType::Continuous && CurrentEffort.State != EEffortAudioState::Consumed)
				// 		return false;
				// }

				if(EffortComp.GetExertion() <= EffortComp.GetEffortMaxClampValue(CurrentEffort))
					return false;
			}
		}

		return true;
	}

	float GetActiveEffortFactor(const FEffortData& Recovery )
	{
		FEffortData& CurrentEffort = EffortComp.GetCurrentEffortData();

		const float BaseFactor = 1;
		const int32 CategoryDiff = Math::Max(1, int(Recovery.Intensity) - int(CurrentEffort.Intensity));

		return BaseFactor * CategoryDiff;		
	}

	float GetIntensityLevelFactor()
	{		
		const float CurrExertion = EffortComp.GetExertion();

		if(CurrExertion == 0.0)
			return 1.0;

		if(CurrExertion < EffortSettings.LowIntensityRange)
			return EffortSettings.LowIntensityRecoveryFactor;

		if(CurrExertion < EffortSettings.MediumIntensityRange)
			return EffortSettings.MediumIntensityRecoveryFactor;

		if(CurrExertion < EffortSettings.HighIntensityRange)
			return EffortSettings.HighIntensityRecoveryFactor;

		return EffortSettings.CriticalIntensityRecoveryFactor;
	}
}
