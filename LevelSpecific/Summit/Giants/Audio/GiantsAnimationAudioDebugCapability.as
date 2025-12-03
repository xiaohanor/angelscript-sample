class UGiantsAnimationAudioDebugCapability : UHazeCapability
{
#if EDITOR
	ATheGiant Giant;
	UHazeMovementAudioComponent MoveAudioComp;	

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Giant = Cast<ATheGiant>(Owner);
		MoveAudioComp = UHazeMovementAudioComponent::Get(Giant);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return Giant.AnimNotifyToEventDebugMap.Num() > 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Giant.AnimNotifyToEventDebugMap.Num() == 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnLogActive(FTemporalLog TemporalLog)
	{
		auto CustomLog = TEMPORAL_LOG("Audio/Giants");
		auto Group = CustomLog.Page(Giant.GetActorLabel());
		for(auto& Pair : Giant.AnimNotifyToEventDebugMap)
		{
			FName EventName = Pair.Key;
			FName AnimationName = Pair.Value;
			Group.Value(AnimationName.ToString(), EventName);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		auto CustomLog = TEMPORAL_LOG("Audio/Giants");
		auto Group = CustomLog.Page(Giant.GetActorLabel());

		TArray<FName> ActiveGroups;
		MoveAudioComp.GetActiveMovementGroups(ActiveGroups);

		for(auto MovementGroup : ActiveGroups)
		{			
			Group.Value(MovementGroup.ToString(), MoveAudioComp.GetActiveMovementTag(MovementGroup));
		}
	}
#endif
}