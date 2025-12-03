UCLASS(Abstract)
class UVO_Player_SpaceWalk_Breathing_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OxygenPumpSuccesful(FSpaceWalkOxygenInteractionEffectParams SpaceWalkOxygenInteractionEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OxygenPumpFailed(FSpaceWalkOxygenInteractionEffectParams SpaceWalkOxygenInteractionEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OxygenFailedTimeout(FSpaceWalkOxygenInteractionEffectParams SpaceWalkOxygenInteractionEffectParams){}

	UFUNCTION(BlueprintEvent)
	void OxygenCompleted(){}

	UFUNCTION(BlueprintEvent)
	void SpaceWalkOxygen_OxygenMeterWidgetShown(){}

	UFUNCTION(BlueprintEvent)
	void SpaceWalkOxygen_OxygenPipConsumed(){}

	UFUNCTION(BlueprintEvent)
	void SpaceWalkOxygen_OxygenPipRefilled(){}

	UFUNCTION(BlueprintEvent)
	void SpaceWalkOxygen_OxygenLowWarningAdded(){}

	UFUNCTION(BlueprintEvent)
	void SpaceWalkOxygen_OxygenLowWarningRemoved(){}

	UFUNCTION(BlueprintEvent)
	void SpaceWalkOxygen_OxygenDeathTriggered(){}

	/* END OF AUTO-GENERATED CODE */

	
 	/******************************************************************************************************************* */
	/*										BREATHING															 		 */
 	/******************************************************************************************************************* */

	// Internal
    //--------------------------------------------------------------------------------------------------------------------

	// The currently targeted length of inhales (seconds)
	UPROPERTY(NotEditable, DisplayName = "Current Breathing Interval", Category = BreathingLogic)
	float CurrentBreathingInterval = 0.01;

	float ExertionCurveAlpha = 0.0;
	float RecoveryCurveAlpha = 0.0;

	bool bWasRecovering = false;

	UPROPERTY(NotEditable, Category = BreathingLogic)
	UHazeAudioEvent CurrentBreathingEvent;

	UPROPERTY(BlueprintReadWrite)
	float ManuallySetExertionValue = 0.0;

	UPROPERTY(BlueprintReadWrite)
	float ManuallySetBreathingInterval = 1.0;

	const FName BREATHING_MOVEMENT_GROUP_NAME = n"Player_Breathing";

	// Public
    //--------------------------------------------------------------------------------------------------------------------

	UPROPERTY(Category = BreathingLogic)
	TMap<EEffortAudioIntensity, FBreathingData> BreathingDatas;

	UPROPERTY(Category = BreathingLogic)
	UCurveFloat ExertionRateCurve;

	UPROPERTY(Category = BreathingLogic)
	UCurveFloat RecoveryRateCurve;

	UPROPERTY(Category = BreathingLogic)
	UCurveFloat OpenCloseMouthChanceCurve;

	UPROPERTY(Category = BreathingLogic)
	UCurveFloat OpenCloseMouthChanceCurveWallRun;

	// Target rate of breathing when at no exertion
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, ForceUnits = "Seconds", Delta = 0.1))
	float BreathingIntervalMin = 10.0;

	// Target rate of breathing when at max exertion
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, ForceUnits = "Seconds", Delta = 0.1))
	float BreathingIntervalMax = 0.3;

	// How quickly does the character become tired (out of breath)
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, Units = "Times", Delta = 0.1))
	float ExertionFactor = 1.0;

	// How quickly does the character recover from exertion (catches their breath)
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, Units = "Times", Delta = 0.1))
	float RecoveryFactor = 1.0;	

	private FBreathingTagData CurrentBreathingData;

	UPROPERTY(NotEditable, Category = "Internal")
	FHazeAudioPostEventInstance CurrentBreathingEventInstance;

	UPROPERTY(Transient, Category = BreathingLogic)
	bool bSetMakeUpGain = true;

	EEffortAudioIntensity GetCurrentBreathingIntensity() const property
	{
		// const float CurrExertion = EffortComp.GetExertion();
		const float CurrExertion = ManuallySetExertionValue;

		// if(CurrExertion == 0.0)
		// 	return EEffortAudioIntensity::None;

		if(CurrExertion < 25.0)
			return EEffortAudioIntensity::Low;

		if(CurrExertion < 50)
			return EEffortAudioIntensity::Medium;

		if(CurrExertion < 75)
			return EEffortAudioIntensity::High;

		return EEffortAudioIntensity::Critical;
	}

	#if EDITOR	
	UFUNCTION()
	TArray<FString> GetBreathingTags() const
	{
		TArray<FString> TagsAsString;

		UHazeMovementAudioTagsAsset TagsAsset = Cast<UHazeMovementAudioTagsAsset>(LoadObject(nullptr, "/Game/Core/Audio/DA_MovementAudioTags"));
		FMovementAudioTagsGroup BreathingTagsGroup;

		TagsAsset.MovementTagsGroups.Find(n"Player_Breathing", BreathingTagsGroup);	

		for(auto& NameTag : BreathingTagsGroup.Tags)
		{
			TagsAsString.Add(NameTag.ToString());
		}

		return TagsAsString;
	}

	private float ExhaleTimestamp = 0.0;
	#endif
	
	
	/******************************************************************************************************************* */
	/*										GAMEPLAY 																	 */
 	/******************************************************************************************************************* */

	// Character movement speed
	UPROPERTY(NotEditable, Category = GameplayLogic)
	float MovementSpeed;

	// Current Breathing movement state set from animation
	UPROPERTY(NotEditable, Category = GameplayLogic)
	FName MovementTag;

	// Internal maps of breathing events
	TMap<FName, UHazeAudioEvent> ThreatInhaleEvents;
	TMap<FName, UHazeAudioEvent> ThreatExhaleEvents;

	TMap<FName, UHazeAudioEvent> HealthStateInhaleEvents;
	TMap<FName, UHazeAudioEvent> HealthStateExhaleEvents;

	float CycleTimer = 0.0;
	FTimerHandle DelayedBreathingStartHandle;

	float CachedRandomCycle = 0.0;
	float CachedRandomBreathingInterval = 0.0;
	int BreathingCycleCounter = -1;
	int TargetBreathingCycleCounter = 0;

	bool GetbIsInOpenMouthCycle() const property
	{
		return EffortComp.bIsInOpenMouthBreathingCycle;
	}
	
	bool bTickCycle = true;
	private EBreathingType CurrentBreathingState;
	private bool bWasBlockedByTag = false;


	UPlayerHealthComponent HealthComp;
	UHazeMovementAudioComponent MovementAudioComp;
	UPlayerEffortAudioComponent EffortComp;

	bool bVoxWasActive = false;

	UFUNCTION(BlueprintEvent)
	void OnVoxStatusChanged(bool bIsActive) {};

	bool IsVoxActive() const
	{
		return UHazeVoxRunner::Get().IsActorActive(PlayerOwner) ;
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		MovementAudioComp = UHazeMovementAudioComponent::Get(PlayerOwner);
		MovementAudioComp.OnMovementTagChanged.AddUFunction(this, n"OnMovementChanged");
		EffortComp = UPlayerEffortAudioComponent::Get(PlayerOwner);
		HealthComp = UPlayerHealthComponent::Get(PlayerOwner);
		HealthComp.OnReviveTriggered.AddUFunction(this, n"OnPlayerRespawn");

		MovementTag = n"Idle";		
		UpdateTargetRates();
		

		#if EDITOR
		TemporalLog::RegisterExtender(this, PlayerOwner, "Audio/Breathing", n"PlayerBreathingTemporalLogExtender", );
		#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		bVoxWasActive = IsVoxActive();
		OnVoxStatusChanged(bVoxWasActive);
		// If we are resuming after being blocked by movement, start on exhale to simulate that player was holding breath.
		StartBreathingCycle(bStartDelayed = true);
	}	

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		DelayedBreathingStartHandle.ClearTimerAndInvalidateHandle();
		BP_StopBreathingCycle();
		bWasBlockedByTag = MovementAudioComp.IsMovementBlocked(EMovementAudioFlags::Breathing);

		// Instantly stop any breathing oneshot instance
		CurrentBreathingEventInstance.Stop(0);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "Start Breathing")
	void BP_StartBreathingCycle() {};

	UFUNCTION(BlueprintEvent, DisplayName = "Start Breathing Exhale")
	void BP_StartBreathingCycleOnExhale() {};

	UFUNCTION(BlueprintEvent, DisplayName = "Stop Breathing")
	void BP_StopBreathingCycle() {};

	UFUNCTION(BlueprintEvent, DisplayName = "On Force Inhale")
	void BP_PerformForcedInhale() {};

		
	private UHazeAudioEvent GetCurrentBreathingEvent(const EBreathingType& Type)
	{
		FBreathingData BreathingData;	
		BreathingDatas.Find(CurrentBreathingIntensity, BreathingData);	

		FBreathingTagEvents TagEvents = BreathingData.DefaultBreathingEvents;
		BreathingData.SpecialBreathingEvents.Find(MovementTag, TagEvents);

		UHazeAudioEvent WantedBreathingEvent = nullptr;
		if(Type == EBreathingType::Inhale)
		{
			switch(CurrentBreathingIntensity)
			{
				case(EEffortAudioIntensity::Low): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.LowIntensityOpenMouthInhaleEvent : TagEvents.LowIntensityClosedMouthInhaleEvent; break;
				case(EEffortAudioIntensity::Medium): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.MediumIntensityOpenMouthInhaleEvent : TagEvents.MediumIntensityClosedMouthInhaleEvent; break;
				case(EEffortAudioIntensity::High): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.HighIntensityOpenMouthInhaleEvent : TagEvents.HighIntensityClosedMouthInhaleEvent; break;
				case(EEffortAudioIntensity::Critical): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.CriticalIntensityOpenMouthInhaleEvent : TagEvents.CriticalIntensityClosedMouthInhaleEvent; break;
				default: break;
			}
		}
		else if(Type == EBreathingType::Exhale)
		{
			switch(CurrentBreathingIntensity)
			{
				case(EEffortAudioIntensity::Low): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.LowIntensityOpenMouthExhaleEvent : TagEvents.LowIntensityClosedMouthExhaleEvent; break;
				case(EEffortAudioIntensity::Medium): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.MediumIntensityOpenMouthExhaleEvent : TagEvents.MediumIntensityClosedMouthExhaleEvent; break;
				case(EEffortAudioIntensity::High): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.HighIntensityOpenMouthExhaleEvent : TagEvents.HighIntensityClosedMouthExhaleEvent; break;
				case(EEffortAudioIntensity::Critical): WantedBreathingEvent = bIsInOpenMouthCycle ? TagEvents.CriticalIntensityOpenMouthExhaleEvent : TagEvents.CriticalIntensityClosedMouthExhaleEvent; break;
				default: break;
			}
		}

		return WantedBreathingEvent;	
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
		CachedRandomBreathingInterval = Math::RandRange(CurrentBreathingData.RandomOffsetMin, CurrentBreathingData.RandomOffsetMax);

		// Quick fix for faster recovery in idle
		if(MovementTag == n"Idle")
			RecoveryFactor = 1.0;
		else
			RecoveryFactor = 1.0;
	}

	UFUNCTION(BlueprintCallable)
	void ToggleCycleCounter()
	{
		++BreathingCycleCounter;
		if(BreathingCycleCounter < TargetBreathingCycleCounter)
			return;

		// const float CurrExertion = EffortComp.GetExertion();
		const float CurrExertion = ManuallySetExertionValue;
		

		if(CurrExertion <= 25) // LOW
		{
			TargetBreathingCycleCounter = Math::RandRange(1, 2);
		}
		else if(CurrExertion <= 50) // MID
		{
			TargetBreathingCycleCounter = Math::RandRange(1, 3);
		}
		else 															// HIGH
		{
			TargetBreathingCycleCounter = Math::RandRange(2, 3);
		}

		BreathingCycleCounter = 0;
		OnStartNewBreathingCycles();
	}

	private void OnStartNewBreathingCycles()
	{
		if(OpenCloseMouthChanceCurve == nullptr)
			return;

		if(OpenCloseMouthChanceCurveWallRun == nullptr)
			return;

		// const float CurrExertion = EffortComp.GetExertion();
		const float CurrExertion = ManuallySetExertionValue;
		float OpenMouthChanceValue;

		// Switch OpenMouthChanceCurve depending on Movement tag (WallRun is the only exception currently, Feb 2024) EV. OPTIMIZE IN THE FUTURE
		if (MovementTag == n"WallRun")
		{
			OpenMouthChanceValue = OpenCloseMouthChanceCurveWallRun.GetFloatValue(CurrExertion);
		}
		else
		{
			OpenMouthChanceValue = OpenCloseMouthChanceCurve.GetFloatValue(CurrExertion);
		}

		EffortComp.bIsInOpenMouthBreathingCycle = Math::RandRange(0.0, 100) < OpenMouthChanceValue;
		//Print("EffortComp.bIsInOpenMouthBreathingCycle" + EffortComp.bIsInOpenMouthBreathingCycle, 0,false);
	}

	UFUNCTION()
	void OnPlayerRespawn()
	{
		CurrentBreathingInterval = BreathingIntervalMin;
	}

/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

	UFUNCTION(BlueprintCallable)
	void SetBreathingEvent(const EBreathingType& Type)
	{
		CurrentBreathingEvent = GetCurrentBreathingEvent(Type);
		CurrentBreathingState = Type;
	}

	UFUNCTION()
	void OnMovementChanged(FName InGroup, FName Tag, bool bIsEnter, bool bIsOverride)
	{
		if(!bIsEnter)
			return;

		if(InGroup.IsEqual(BREATHING_MOVEMENT_GROUP_NAME))
		{
			UpdateBreathingTag(Tag);
		}
	}

	private void UpdateBreathingTag(const FName Tag)
	{				
		if(MovementTag.IsEqual(Tag))
			return;

		// Breathing-tag has changed
		MovementTag = Tag;


		UpdateTargetRates(); 
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		// Set breathing rates for this frame

		// Rate from BreathingData
		// Factors from Exhaustion

		// Factors from Health
		// Factors from Threat

		// Offset by cached random value
	
		float CurveBreathingRate = 0.0;	

		const bool bIsRecovering = EffortComp.IsRecovering();
		if(!bWasRecovering && bIsRecovering)
		{
			OnSwitchCurveAlphas(true);
		}
		else if(bWasRecovering && !bIsRecovering)
		{
			OnSwitchCurveAlphas(false);
		}
		bWasRecovering = bIsRecovering;

		const float CurveValue = GetFrameCurveValue();		

		const float TargetBreathingIntervalClamped = Math::Clamp(CurveValue + CachedRandomBreathingInterval, BreathingIntervalMax,  BreathingIntervalMin);
		CurrentBreathingInterval = Math::FInterpTo(CurrentBreathingInterval, TargetBreathingIntervalClamped, DeltaSeconds, 2.0);	


		// Query Vox-status. So many latent actions in the BP of this SoundDef might keep it from deactivating, thus having breathing overlap with VOX.
		// We keep poll it while active for extra safety handling
		const bool bVoxActive = IsVoxActive();
		if(bVoxActive != bVoxWasActive)
		{
			OnVoxStatusChanged(bVoxActive);
		}

		bVoxWasActive = bVoxActive;
	}

	void OnSwitchCurveAlphas(bool bStartRecovering)
	{
		if(bStartRecovering)
		{
			RecoveryCurveAlpha = ExertionCurveAlpha;
		}
		else
		{
			ExertionCurveAlpha = RecoveryCurveAlpha;
		}
	}

	private float GetFrameCurveValue()
	{	
		float CurveValue = 0.0;
		if(!EffortComp.IsRecovering())
		{	
			if(ExertionRateCurve != nullptr)
			{
				const float ExertionAlpha = Math::Saturate(ExertionRateCurve.GetFloatValue(ExertionCurveAlpha) * ExertionFactor);
				CurveValue =  Math::Lerp(BreathingIntervalMax, BreathingIntervalMin, ExertionAlpha);
	
			}					
		}
		else if(RecoveryRateCurve != nullptr)
		{	
			const float RecoveryAlpha = Math::Saturate(RecoveryRateCurve.GetFloatValue(RecoveryCurveAlpha) * RecoveryFactor);
			CurveValue =  Math::Lerp(BreathingIntervalMin, BreathingIntervalMax, RecoveryAlpha);			
		}

		// const float CurrExertion = EffortComp.GetExertion();
		const float CurrExertion = ManuallySetExertionValue;
		ExertionCurveAlpha = CurrExertion;
		RecoveryCurveAlpha = 100 - CurrExertion;
		return CurveValue;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentExertionValue()
	{
		// return EffortComp.GetExertion();
		return ManuallySetExertionValue;
	}

}