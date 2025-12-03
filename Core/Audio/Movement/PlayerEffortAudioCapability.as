class UPlayerEffortAudioCapability : UHazePlayerCapability
{
	default DebugCategory = n"Audio";
	default CapabilityTags.Add(n"PlayerMovementEffortAudio");
	default TickGroup = EHazeTickGroup::Audio;
	default TickGroupOrder = 0;

	UPlayerEffortAudioComponent EffortComp;
	UHazeMovementComponent MoveComp;
	UHazeMovementAudioComponent MoveAudioComp;

	float EffortClampMax;	

	bool bConsumedEffort = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		EffortComp = UPlayerEffortAudioComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		MoveAudioComp = UHazeMovementAudioComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(EffortComp.EffortsAsset == nullptr)
			return false;

		if(!EffortComp.HasPendingEffort())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(EffortComp.GetCurrentEffortData().State == EEffortAudioState::Handling)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bConsumedEffort = false;

		FEffortData& EffortData = EffortComp.GetCurrentEffortData(); 
		if(EffortData.Intensity == EEffortAudioIntensity::None)
			return;

		EffortData.State = EEffortAudioState::Handling;

		if(EffortData.PushType == EEffortAudioPushType::Immediate)
		{
			const float MaxClampValue = EffortComp.GetEffortMaxClampValue(EffortData);

			EffortData.EffortTotal = EffortData.EffortFactor;
			EffortComp.SetEffortCurveAlpha(EffortData.EffortTotal, MaxClampValue / 100);

			// Get frame value from curve			
			float IncrementedExertion = GetExertionCurveValue(EffortData, MaxClampValue); 	

			EffortComp.IncrementExertion(IncrementedExertion);
		
			EffortComp.ConsumeEffort(true);
			bConsumedEffort = true;
		}
		else
		{
			EffortClampMax = EffortComp.GetEffortMaxClampValue(EffortData);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bConsumedEffort)
		{
			FEffortData& EffortData = EffortComp.GetCurrentEffortData(); 

			if(EffortData.Intensity != EEffortAudioIntensity::None && EffortData.Tag != NAME_None)
				EffortComp.ConsumeEffort();
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FEffortData& EffortData = EffortComp.GetCurrentEffortData(); 
		if(EffortData.PushType != EEffortAudioPushType::Continuous)
			return;

		// if(EffortComp.bIsRecovering)
		// 	return;

		// Check if movement was interrupted, if so early out
		if(MoveAudioComp.GetActiveMovementTag(EffortData.Group) != EffortData.Tag)
		{
			EffortComp.ConsumeEffort(bWasCompleted = true);
			bConsumedEffort = true;
			return;
		}

		const float EffortMaxClampValue = EffortComp.GetEffortMaxClampValue(EffortData);

		// Increment current effort over time
		const float FactorIncrementation = EffortData.EffortFactor * DeltaTime;
		EffortComp.SetEffortCurveAlpha(FactorIncrementation, EffortMaxClampValue / 100);	

		// Get frame value from curve		
		float IncrementedExertion = GetExertionCurveValue(EffortData, EffortMaxClampValue); 

		// Apply multiplier from slope tilt
		const float TiltMultiplier = GetSlopeTiltMultiplier();	
		IncrementedExertion *= TiltMultiplier;

		const float Remainder = Math::Max(0, EffortClampMax - EffortData.EffortTotal);
		EffortData.EffortTotal += Math::Min(FactorIncrementation, Remainder);

		// If we cannot keep incrementing this effort, consume it and send it off as a pending recovery
		if(EffortData.EffortTotal >= EffortClampMax)
		{		
			bConsumedEffort = true;
		}

		EffortComp.SetEffortExertion(IncrementedExertion, DeltaTime);
		//EffortComp.IncrementExertion(IncrementedExertion);
	}	

	float GetExertionCurveValue(FEffortData& EffortData, const float EffortMaxClampValue)
	{
		float MaxClampRange = 0.0;
		float CurveValue = EffortComp.GetValueFromCurve(EffortData, MaxClampRange);	
		const float NormalizedCurveValue = Math::GetMappedRangeValueClamped(FVector2D(0.0, EffortMaxClampValue), FVector2D(0.0, EffortMaxClampValue), CurveValue);
		return NormalizedCurveValue;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		auto CurrentEffort = EffortComp.GetCurrentEffortData();

		const FString PlayerName = Player.IsMio() ? "Mio" : "Zoe";
		auto Log = TEMPORAL_LOG(Player, "Audio/Exertion");
		Log.Value("Effort active", EffortComp.bHasValidEffort);
		Log.Value("Is Recovering", EffortComp.IsRecovering());

		Log.Value("Current", EffortComp.GetExertion());

		FName ActiveEffortName = EffortComp.bHasValidEffort ? CurrentEffort.Tag : n"None";

		EEffortAudioIntensity Intensity = EEffortAudioIntensity(CurrentEffort.Intensity);	
		FString IntensityAsString = f"{Intensity: n}";
		FName ActiveIntensityString = EffortComp.bHasValidEffort ? FName(IntensityAsString) : n"None";

		float EffortTotal = EffortComp.bHasValidEffort ? CurrentEffort.EffortTotal : 0;

		Log.Value("Current Effort", f"{ActiveEffortName} - {ActiveIntensityString} - {EffortTotal}");	
		Log.Value("Effort Curve Alpha", EffortComp.EffortCurveAlpha);
		Log.Value("Recovery Curve Alpha", EffortComp.RecoveryCurveAlpha);

		#if EDITOR
		Log.Value("Recoveries", EffortComp.GetRecoveriesAsString());
		#endif

		Log.Value("Effort Target", EffortComp.EffortTarget);
		Log.Value("Recovery Target", EffortComp.RecoveryTarget);

		Log.Value("Is Stressed: ", EffortComp.IsStressed());
	}

	private float GetSlopeTiltMultiplier()
	{
		if(!MoveComp.IsOnWalkableGround())
			return 1.0;

		FVector Velo = MoveComp.GetVelocity();

		const FVector ForwardVeloDir = Velo.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		Velo.Normalize();

		if(Velo.DotProduct(MoveComp.WorldUp) >= 0)
		{
			const float TiltDegrees = Math::DotToDegrees(Velo.DotProduct(ForwardVeloDir));

			const float NormalizedTiltMultiplier = Math::Lerp(1.0, EffortComp.EffortsAsset.SlopeTiltEffortMultiplier, Math::GetPercentageBetweenClamped(0.0, 45.0, TiltDegrees));
			return NormalizedTiltMultiplier;
		}

		return 1.0;

	}
}