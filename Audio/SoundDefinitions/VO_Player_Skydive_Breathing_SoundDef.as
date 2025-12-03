
UCLASS(Abstract)
class UVO_Player_Skydive_Breathing_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	// The currently targeted length of inhales (seconds)
	UPROPERTY(NotEditable, DisplayName = "Current Breathing Interval", Category = BreathingLogic)
	float CurrentBreathingInterval = 0.01;

	// UPROPERTY(Category = BreathingLogic)
	// TMap<EEffortAudioIntensity, FBreathingData> BreathingDatas;

	// private FBreathingTagData CurrentBreathingData;

	UPROPERTY(NotEditable, Category = "Internal")
	FHazeAudioPostEventInstance CurrentBreathingEventInstance;

	UPROPERTY(NotEditable, Category = BreathingLogic)
	UHazeAudioEvent CurrentBreathingEvent;

	UPROPERTY(EditDefaultsOnly, Category = BreathingLogic)
	float SphereTraceRadius = 1000;

	UPROPERTY(EditDefaultsOnly, Category = BreathingLogic)
	float SphereTraceLength = 5000;
	UPROPERTY(EditDefaultsOnly, Category = BreathingLogic, Meta = (EditCondition = "SphereTraceRadius > 0.0 && SphereTraceLength > 0.0"))
	float TraceCollisionMinimumBreathingRate = 0.25;
	
	private bool bShouldSphereTrace = false;
	float CycleTimer = 0.0;
	FTimerHandle DelayedBreathingStartHandle;

	float CachedRandomCycle = 0.0;
	float CachedRandomBreathingInterval = 0.0;
	// int BreathingCycleCounter = -1;
	// int TargetBreathingCycleCounter = 0;
	
	bool bTickCycle = true;
	private EBreathingType CurrentBreathingState;

	private UPlayerBreathingAudioSettings BreathingSettings;

	UHazeMovementComponent MoveComp;
	UPlayerSkydiveComponent SkydiveComp;
	UHazeMovementAudioComponent MovementAudioComp;

	UFUNCTION(BlueprintEvent, DisplayName = "Start Breathing")
	void BP_StartBreathingCycle() {};

	UFUNCTION(BlueprintEvent, DisplayName = "Start Breathing Exhale")
	void BP_StartBreathingCycleOnExhale() {};

	UFUNCTION(BlueprintEvent, DisplayName = "Stop Breathing")
	void BP_StopBreathingCycle() {};

	UFUNCTION(BlueprintEvent, DisplayName = "On Force Inhale")
	void BP_PerformForcedInhale() {};

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MoveComp = UHazeMovementComponent::Get(PlayerOwner);
		SkydiveComp = UPlayerSkydiveComponent::Get(PlayerOwner);
		MovementAudioComp = UHazeMovementAudioComponent::Get(PlayerOwner);
	}		

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MovementAudio::Player::CanPerformBreathing(MovementAudioComp))
			return true;

		if(UHazeVoxRunner::Get().IsActorActive(PlayerOwner))
			return true;

		return false; 
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MovementAudio::Player::CanPerformBreathing(MovementAudioComp))
			return false;

		if(UHazeVoxRunner::Get().IsActorActive(PlayerOwner))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// If we are resuming after being blocked by movement, start on exhale to simulate that player was holding breath.
		StartBreathingCycle(bStartDelayed = true);
		BreathingSettings = UPlayerBreathingAudioSettings::GetSettings(PlayerOwner);		

		bShouldSphereTrace = (SphereTraceLength > 0.0 && SphereTraceRadius > 0.0);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DelayedBreathingStartHandle.ClearTimerAndInvalidateHandle();
		BP_StopBreathingCycle();

		// Instantly stop any breathing oneshot instance
		CurrentBreathingEventInstance.Stop(0);
	}

	private void StartBreathingCycle(const bool bStartDelayed = false, const bool bStartOnExhale = false)
	{
		// Wait a random time amount before starting breathing logic to keep things fricky-fricky-fresh
		const float InitialStartDelay = Math::RandRange(0.01, 0.01);
		CycleTimer = InitialStartDelay + CurrentBreathingInterval;

		if(bStartDelayed)
		{
			if(!bStartOnExhale)
				DelayedBreathingStartHandle = Timer::SetTimer(this, n"BP_StartBreathingCycle", InitialStartDelay);
			else
				DelayedBreathingStartHandle = Timer::SetTimer(this, n"BP_StartBreathingCycleOnExhale", InitialStartDelay);
		}
		else
		{
			if(!bStartOnExhale)
				BP_StartBreathingCycle();
			else
				BP_StartBreathingCycleOnExhale();
		}
	}

	UFUNCTION(BlueprintCallable)
	void UpdateTargetRates()
	{
		//CachedRandomBreathingInterval = Math::RandRange(CurrentBreathingData.RandomOffsetMin, CurrentBreathingData.RandomOffsetMax);
	}

	// UFUNCTION(BlueprintCallable)
	// void ToggleCycleCounter()
	// {
	// 	++BreathingCycleCounter;
	// 	if(BreathingCycleCounter < TargetBreathingCycleCounter)
	// 		return;

	// 	const float CurrExertion = EffortComp.GetExertion();

	// 	if(CurrExertion <= BreathingSettings.LowExertionCycleThreshold) // LOW
	// 	{
	// 		TargetBreathingCycleCounter = Math::RandRange(1, 2);
	// 	}
	// 	else if(CurrExertion <= BreathingSettings.MidExertionCycleThreshold) // MID
	// 	{
	// 		TargetBreathingCycleCounter = Math::RandRange(1, 3);
	// 	}
	// 	else 															// HIGH
	// 	{
	// 		TargetBreathingCycleCounter = Math::RandRange(2, 3);
	// 	}

	// 	BreathingCycleCounter = 0;
	// 	//OnStartNewBreathingCycles();
	// }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Set breathing rates for this frame
		const float TargetBreathingIntervalClamped = 0.5;
		CurrentBreathingInterval = Math::FInterpTo(CurrentBreathingInterval, TargetBreathingIntervalClamped, DeltaSeconds, 2.0);	

		if(bShouldSphereTrace)
		{
			// Check for objects around the player
			FHazeTraceSettings Trace;	
			Trace.UseCapsuleShape(SphereTraceRadius, SphereTraceRadius / 2);		
			Trace.TraceWithChannel(ECollisionChannel::ECC_WorldDynamic);
			Trace.IgnoreActor(PlayerOwner);
			Trace.IgnoreActor(PlayerOwner.OtherPlayer);

			const FVector Start = PlayerOwner.ActorLocation;
			const FVector End = Start + (-MoveComp.WorldUp * (SphereTraceLength));			
			#if EDITOR
			if(IsDebugging())
				Trace.DebugDrawOneFrame();
			#endif

			FHitResult Hit = Trace.QueryTraceSingle(Start, End);
			if(Hit.bBlockingHit)
			{				
				const float BreathingRateIncrease = Math::GetMappedRangeValueClamped(FVector2D(0.0, SphereTraceLength), FVector2D(TraceCollisionMinimumBreathingRate, 0.0), Hit.Distance);
				CurrentBreathingInterval = Math::Max(0.1, CurrentBreathingInterval - BreathingRateIncrease);
			}
		}
	}

	// private void OnStartNewBreathingCycles()
	// {
	// 	if(OpenCloseMouthChanceCurve == nullptr)
	// 		return;

	// 	if(OpenCloseMouthChanceCurveWallRun == nullptr)
	// 		return;

	// 	const float CurrExertion = EffortComp.GetExertion();
	// 	float OpenMouthChanceValue;

	// 	// Switch OpenMouthChanceCurve depending on Movement tag (WallRun is the only exception currently, Feb 2024) EV. OPTIMIZE IN THE FUTURE
	// 	if (MovementTag == n"WallRun")
	// 	{
	// 		OpenMouthChanceValue = OpenCloseMouthChanceCurveWallRun.GetFloatValue(CurrExertion);
	// 	}
	// 	else
	// 	{
	// 		OpenMouthChanceValue = OpenCloseMouthChanceCurve.GetFloatValue(CurrExertion);
	// 	}

	// 	EffortComp.bIsInOpenMouthBreathingCycle = Math::RandRange(0.0, 100) < OpenMouthChanceValue;
	// 	//Print("EffortComp.bIsInOpenMouthBreathingCycle" + EffortComp.bIsInOpenMouthBreathingCycle, 0,false);
	// }

	// UFUNCTION()
	// void OnPlayerRespawn()
	// {
	// 	CurrentBreathingInterval = BreathingIntervalMin;
	// }
}