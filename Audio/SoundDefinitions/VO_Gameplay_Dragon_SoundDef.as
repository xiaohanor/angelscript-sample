struct FDragonVocalizationData
{
	UPROPERTY()
	UHazeAudioEvent VocalizationEvent = nullptr;

	UPROPERTY()
	int32 TriggerChance = 100;
}


UCLASS(Abstract)
class UVO_Gameplay_Dragon_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	/******************************************************************************************************************* */
	/*										BREATHING															 		 */
 	/******************************************************************************************************************* */

	// Internal
    //--------------------------------------------------------------------------------------------------------------------

	// The currently targeted length of inhales (seconds)
	UPROPERTY(NotEditable, DisplayName = "Current Inhale Interval", Category = BreathingLogic)
	float CurrentInhaleRate = 1.0;

	// The currently targeted length of exhales (seconds)
	UPROPERTY(NotEditable, DisplayName = "Current Exhale Interval", Category = BreathingLogic)
	float CurrentExhaleRate = 1.0;

	// Target rate of inhales when at no exertion
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, ForceUnits = "Seconds", Delta = 0.1))
	float InhaleRateMin = 10.0;

	// Target rate of inhales when at max exertion
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, ForceUnits = "Seconds", Delta = 0.1))
	float InhaleRateMax = 0.3;

	// Target rate of exhales when at no exertion
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, ForceUnits = "Seconds", Delta = 0.1))
	float ExhaleRateMin = 10.0;

	// Target rate of exhales when at max exertion
	UPROPERTY(Category = BreathingLogic, meta = (UIMin = 0.1, UIMax = 10.0, ForceUnits = "Seconds", Delta = 0.1))
	float ExhaleRateMax = 0.3;

	UPROPERTY(NotEditable, Category = BreathingLogic)
	UHazeAudioEvent CurrentBreathingEvent;

	UPROPERTY(NotEditable, Category = "Internal")
	FHazeAudioPostEventInstance CurrentBreathingEventInstance;

	UPROPERTY(NotEditable, Category = "Internal")
	FHazeAudioPostEventInstance CurrentVocalizationEventInstance;

	private FBreathingTagData CurrentBreathingData;
	const FName BREATHING_MOVEMENT_GROUP_NAME = n"Dragon_Breathing";

	UPROPERTY(Category = BreathingTagData, Meta = (GetOptions = "GetBreathingTags"))
	TMap<FName, FBreathingTagData> BreathingTagDatas;

	UPROPERTY(Category = Vocalizations, Meta = (GetOptions = "GetBreathingTags"))
	TMap<FName, FDragonVocalizationData> VocalizationDatas;

	private EBreathingType CurrentBreathingState;

	#if EDITOR	
	UFUNCTION()
	TArray<FString> GetBreathingTags() const
	{
		TArray<FString> TagsAsString;

		UHazeMovementAudioTagsAsset TagsAsset = Cast<UHazeMovementAudioTagsAsset>(LoadObject(nullptr, "/Game/Core/Audio/DA_MovementAudioTags"));
		FMovementAudioTagsGroup BreathingTagsGroup;

		TagsAsset.MovementTagsGroups.Find(n"Dragon_Breathing", BreathingTagsGroup);	

		for(auto& NameTag : BreathingTagsGroup.Tags)
		{
			TagsAsString.Add(NameTag.ToString());
		}

		return TagsAsString;
	}

	private float ExhaleTimestamp = 0.0;
	#endif

	float CycleTimer = 0.0;
	float CachedRandomBreathingInterval = 0.0;

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		StartBreathingCycle(bStartDelayed = true);
	}	

	UFUNCTION(BlueprintEvent, DisplayName = "Start Breathing")
	void BP_StartBreathingCycle() {};

	UFUNCTION(BlueprintEvent, DisplayName = "Start Breathing Exhale")
	void BP_StartBreathingCycleOnExhale() {};

	UFUNCTION(BlueprintEvent, DisplayName = "Stop Breathing")
	void BP_StopBreathingCycle() {};

	UFUNCTION(BlueprintEvent, DisplayName = "On Force Inhale")
	void BP_PerformForcedInhale() {};

		private void StartBreathingCycle(const bool bStartDelayed = false, const bool bStartOnExhale = false)
	{
		// Wait a random time amount before starting breathing logic to keep things fresh
		const float InitialStartDelay = Math::RandRange(0.25, 3.0);
		CycleTimer = InitialStartDelay + CurrentInhaleRate + CurrentExhaleRate;

		if(bStartDelayed)
		{
			if(!bStartOnExhale)
				Timer::SetTimer(this, n"BP_StartBreathingCycle", InitialStartDelay);
			else
				Timer::SetTimer(this, n"BP_StartBreathingCycleOnExhale", InitialStartDelay);
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
	}

	UFUNCTION(BlueprintCallable)
	void SetBreathingEvent(const EBreathingType& Type)
	{
		// TODO: Need to do more intelligent branching once other layers of complexity are added (Health, Threat level etc.)
		//const FName CurrMovementState = MovementAudio::Player::GetMovementState(PlayerOwner, n"Breathing");

		if(Type == EBreathingType::Inhale)
		{	
			CurrentBreathingEvent = CurrentBreathingData.OpenMouthInhaleEvent;
		}
		else
		{
			CurrentBreathingEvent = CurrentBreathingData.OpenMouthExhaleEvent;
			#if EDITOR
			ExhaleTimestamp = Time::GetGameTimeSeconds();
			#endif
		}

		CurrentBreathingState = Type;
	}

}