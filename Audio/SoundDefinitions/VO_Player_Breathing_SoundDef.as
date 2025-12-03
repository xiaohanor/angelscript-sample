#if EDITOR
class UPlayerBreathingTemporalLogExtender : UTemporalLogUIExtender
{
	FString GetUIName(FHazeTemporalLogReport Report) const override
	{
		return "Player Breathing Temporal Extender";
	}

	bool ShouldShow(FHazeTemporalLogReport Report) const override
	{
	#if EDITOR
		auto BreathingSoundDef = Cast<UVO_Player_Breathing_SoundDef>(Report.AssociatedObject);
		return BreathingSoundDef != nullptr;
	#else
		return false;
	#endif
	}

	void DrawUI(UHazeImmediateDrawer Drawer, FHazeTemporalLogReport Report) const override
	{	
		FHazeImmediateSectionHandle Section = Drawer.Begin();
		FHazeImmediateHorizontalBoxHandle Box = Section.HorizontalBox();	
		if(Box.Button("Exertion Up"))
		{
			auto BreathingSoundDef = Cast<UVO_Player_Breathing_SoundDef>(Report.AssociatedObject);
			if(BreathingSoundDef != nullptr)
			{
				auto EffortComp = UPlayerEffortAudioComponent::Get(BreathingSoundDef.PlayerOwner);		
				EffortComp.Debug_PushEffort(10.0);
			}
		}	
		if(Box.Button("Exertion Down"))
		{
			auto BreathingSoundDef = Cast<UVO_Player_Breathing_SoundDef>(Report.AssociatedObject);
			if(BreathingSoundDef != nullptr)
			{
				auto EffortComp = UPlayerEffortAudioComponent::Get(BreathingSoundDef.PlayerOwner);		
				EffortComp.Debug_RecoverEffort(10);
			}
		}
	}
}
#endif

enum EBreathingType
{
	Inhale,
	Exhale
}

struct FBreathingTagEvents
{
	UPROPERTY(EditDefaultsOnly, Category = "Low")
	UHazeAudioEvent LowIntensityOpenMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Low")
	UHazeAudioEvent LowIntensityClosedMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Low")
	UHazeAudioEvent LowIntensityOpenMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Low")
	UHazeAudioEvent LowIntensityClosedMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Medium")
	UHazeAudioEvent MediumIntensityOpenMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Medium")
	UHazeAudioEvent MediumIntensityClosedMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Medium")
	UHazeAudioEvent MediumIntensityOpenMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Medium")
	UHazeAudioEvent MediumIntensityClosedMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "High")
	UHazeAudioEvent HighIntensityOpenMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "High")
	UHazeAudioEvent HighIntensityClosedMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "High")
	UHazeAudioEvent HighIntensityOpenMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "High")
	UHazeAudioEvent HighIntensityClosedMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Critical")
	UHazeAudioEvent CriticalIntensityOpenMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Critical")
	UHazeAudioEvent CriticalIntensityClosedMouthInhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Critical")
	UHazeAudioEvent CriticalIntensityOpenMouthExhaleEvent = nullptr;

	UPROPERTY(EditDefaultsOnly, Category = "Critical")
	UHazeAudioEvent CriticalIntensityClosedMouthExhaleEvent = nullptr;
}

USTRUCT()
struct FBreathingData
{
	UPROPERTY(EditDefaultsOnly, Meta = (ShowOnlyInnerProperties))
	FBreathingTagEvents DefaultBreathingEvents;

	UPROPERTY(EditDefaultsOnly, Meta = (GetOptions = "GetBreathingTags"))
	TMap<FName, FBreathingTagEvents> SpecialBreathingEvents;

	UPROPERTY(Category = Inhale, meta=(UIMin = -10.0, UIMax = 0.0, Delta = 0.1, ForceUnits = "Seconds"))
	float InhaleRandomOffsetMin = 0.0;

	UPROPERTY(Category = Inhale, meta=(UIMin = 0, UIMax = 10.0, Delta = 0.1, ForceUnits = "Seconds"))
	float InhaleRandomOffsetMax = 0.0;
	
	UPROPERTY(Category = Exhale, meta=(UIMin = -10.0, UIMax = 0.0, Delta = 0.1, ForceUnits = "Seconds"))
	float ExhaleRandomOffsetMin = 0.0;

	UPROPERTY(Category = Exhale, meta=(UIMin = 0.0, UIMax = 10.0, Delta = 0.1, ForceUnits = "Seconds"))
	float ExhaleRandomOffsetMax = 0.0;

	UPROPERTY(Category = Inhale, meta=(UIMin = -10.0, UIMax = 0.0, Delta = 0.1, ForceUnits = "Seconds"))
	float InhaleClimbRandomOffsetMin = 0.0;

	UPROPERTY(Category = Inhale, meta=(UIMin = 0, UIMax = 10.0, Delta = 0.1, ForceUnits = "Seconds"))
	float InhaleClimbRandomOffsetMax = 0.0;
	
	UPROPERTY(Category = Exhale, meta=(UIMin = -10.0, UIMax = 0.0, Delta = 0.1, ForceUnits = "Seconds"))
	float ExhaleClimbRandomOffsetMin = 0.0;

	UPROPERTY(Category = Exhale, meta=(UIMin = 0.0, UIMax = 10.0, Delta = 0.1, ForceUnits = "Seconds"))
	float ExhaleClimbRandomOffsetMax = 0.0;
}

UCLASS(Abstract)
class UVO_Player_Breathing_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	
 	/******************************************************************************************************************* */
	/*										BREATHING															 		 */
 	/******************************************************************************************************************* */

	// Internal
    //--------------------------------------------------------------------------------------------------------------------

	// The currently targeted length of inhales (seconds)
	UPROPERTY(NotEditable, DisplayName = "Current Breathing Interval", Category = BreathingLogic)
	float CurrentBreathingInterval = 0.01;

	// How tired the character currently is
	//UPROPERTY(NotEditable, Category = BreathingLogic)
	float CurrentExertion = 1.0;	

	float ExertionCurveAlpha = 0.0;
	float RecoveryCurveAlpha = 0.0;

	bool bWasRecovering = false;

	UPROPERTY(NotEditable, Category = BreathingLogic)
	UHazeAudioEvent CurrentBreathingEvent;

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
		const float CurrExertion = EffortComp.GetExertion();

		if(CurrExertion == 0.0)
			return EEffortAudioIntensity::None;

		if(CurrExertion < EffortSettings.LowIntensityRange)
			return EEffortAudioIntensity::Low;

		if(CurrExertion < EffortSettings.MediumIntensityRange)
			return EEffortAudioIntensity::Medium;

		if(CurrExertion < EffortSettings.HighIntensityRange)
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

	// Current character health
	UPROPERTY(NotEditable, Category = GameplayLogic)
	float CurrentHealth;

    // Will be remade to enum
	// Current state of threat to character
	UPROPERTY(NotEditable, Category = GameplayLogic)
	int ThreatState;	

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

	private UPlayerBreathingAudioSettings BreathingSettings;
	private UPlayerEffortAudioSettings EffortSettings;

	UHazeMovementAudioComponent MovementAudioComp;
	UPlayerEffortAudioComponent EffortComp;
	UPlayerHealthComponent HealthComp;

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
		// If we are resuming after being blocked by movement, start on exhale to simulate that player was holding breath.
		StartBreathingCycle(bStartDelayed = true);
		BreathingSettings = UPlayerBreathingAudioSettings::GetSettings(PlayerOwner);	
		EffortSettings = UPlayerEffortAudioSettings::GetSettings(PlayerOwner);
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

		const float CurrExertion = EffortComp.GetExertion();

		if(CurrExertion <= BreathingSettings.LowExertionCycleThreshold) // LOW
		{
			TargetBreathingCycleCounter = Math::RandRange(1, 2);
		}
		else if(CurrExertion <= BreathingSettings.MidExertionCycleThreshold) // MID
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

		const float CurrExertion = EffortComp.GetExertion();
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

	// returns false if Breathing-type was not overriden by situational instigators
	private bool QueryBreathingTypeOverride(const EBreathingType& Type, UHazeAudioEvent&out OverrideBreathingEvent)
	{
		if(PlayerOwner.PlayerIsInStress())
		{
			FBreathingData BreathingData;
			FBreathingTagEvents TagEvents;
			BreathingDatas.Find(GetCurrentBreathingIntensity(), BreathingData);
			BreathingData.SpecialBreathingEvents.Find(n"Stress", TagEvents);

			// TODO: Add all neccesary logic here to decide on wanted breathing event
			OverrideBreathingEvent = Type == EBreathingType::Inhale ? TagEvents.LowIntensityClosedMouthInhaleEvent : TagEvents.LowIntensityClosedMouthExhaleEvent;
			return true;
		}
		return false;
	}

	UFUNCTION(BlueprintCallable)
	void SetBreathingEvent(const EBreathingType& Type)
	{
		if(QueryBreathingTypeOverride(Type, CurrentBreathingEvent) == false)
		{
			CurrentBreathingEvent = GetCurrentBreathingEvent(Type);
		}
		
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

		#if EDITOR

		const FString PlayerName = PlayerOwner.IsMio() ? "Mio" : "Zoe";
		auto Log = TEMPORAL_LOG(PlayerOwner, "Audio/Breathing",);

		// Cycle Time
		const float ElapsedTime = Time::GetGameTimeSince(ExhaleTimestamp);		
		const float CycleTime = CurrentBreathingInterval - ElapsedTime;
		
		const FString CycleTimeAsString = CurrentBreathingState == EBreathingType::Inhale ? "NewCycle..." : f"TimeLeft: {Math::Clamp(CycleTime, 0, MAX_flt) :.1}";
		Log.Value("BreathingCycle", f"{CurrentBreathingState :n}");
		Log.Value("Cycle Debug", CycleTimeAsString);

		// Event
		const bool bIsPlaying = CurrentBreathingEventInstance.IsPlaying();
		FLinearColor EventDebugColor;
		
		if(bIsPlaying)
			EventDebugColor = FLinearColor::Green;
		else
			EventDebugColor = FLinearColor::Red;

		const FString EventAsString = bIsPlaying ? CurrentBreathingEventInstance.EventName() : "";
		
		Log.Value("Event", EventAsString);	
		Log.Value("Threat", ThreatState);

		Log.Value("Movement Tag", MovementTag.ToString());	
		Log.Value("Exertion", Math::Abs(EffortComp.GetExertion()));	

		Log.Value("Breathing Interval", f"{CurrentBreathingInterval :.1}");	
		Log.Value("Current Intensity", f"{GetCurrentBreathingIntensity() :.1}");	


		Log.Value("Random Interval Min", f"{CurrentBreathingData.RandomOffsetMin :.1}");	
		Log.Value("Random Interval Max", f"{CurrentBreathingData.RandomOffsetMax :.1}");	

		// float OpenMouthPercentage = OpenMouthChanceDeterminator();
		// Log.Value("Open Mouth Chance Percentage", f"{OpenMouthPercentage :.1}");			

		Log.Value("Current Breathing Cycle", f"{BreathingCycleCounter :.1}");			
		Log.Value("Target Breathing Cycle", f"{TargetBreathingCycleCounter :.1}");			
		
 		const float CurrExertion = EffortComp.GetExertion();
		const float OpenMouthChanceValue = OpenCloseMouthChanceCurve.GetFloatValue(CurrExertion);
		const float OpenMouthChanceValueWallRun = OpenCloseMouthChanceCurveWallRun.GetFloatValue(CurrExertion);

//		OnStartNewBreathingCyclesForDebug = OnStartNewBreathingCycles().OpenMouthChanceValue;
		Log.Value("Open Mouth Chance", f"{OpenMouthChanceValue :.1}");	 		
		Log.Value("Open Mouth Chance WallRun", f"{OpenMouthChanceValueWallRun :.1}");	 		

		if(CurrentBreathingEvent != nullptr)
		{
			Log.Value("Breathing asset playing", f"{CurrentBreathingEvent.GetName()}");
		}
		#endif
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

		const float CurrExertion = EffortComp.GetExertion();
		ExertionCurveAlpha = CurrExertion;
		RecoveryCurveAlpha = 100 - CurrExertion;
		return CurveValue;
	}

	UFUNCTION(BlueprintPure)
	float GetCurrentExertionValue()
	{
		return EffortComp.GetExertion();
	}
}