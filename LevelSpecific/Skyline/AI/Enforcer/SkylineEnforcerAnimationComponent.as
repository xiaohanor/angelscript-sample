class USkylineEnforcerAnimationComponent : UActorComponent
{
	UHazeCharacterSkeletalMeshComponent Mesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
	}

	float GetFinalizedTotalDuration(FName Tag, FName SubTag, float OverrideDuration)
	{
		if (OverrideDuration > SMALL_NUMBER)
			return OverrideDuration;

		UAnimSequence Anim = GetRequestedAnimation(Tag, SubTag);
		if (Anim == nullptr)
			return 0.0;
		
		return Anim.PlayLength;
	}

	void FinalizeDurations(FName Tag, FName SubTag, FBasicAIAnimationActionDurations& Durations)
	{
		if (Durations.IsFullySet())
			return;

		UAnimSequence Anim = GetRequestedAnimation(Tag, SubTag);
		if (Anim == nullptr)
			return;

		float ActionTime = Anim.PlayLength;
		float RecoveryTime = Anim.PlayLength;
		TArray<FHazeAnimNotifyStateGatherInfo> ActionNotifyInfo;
		if (Anim.GetAnimNotifyStateTriggerTimes(UBasicAIActionAnimNotify, ActionNotifyInfo) && (ActionNotifyInfo.Num() > 0))
		{
			ActionTime = ActionNotifyInfo[0].TriggerTime;
			RecoveryTime = ActionNotifyInfo.Last().TriggerTime + ActionNotifyInfo.Last().Duration;
		}
		float AnticipationTime = 0.0;
		TArray<FHazeAnimNotifyStateGatherInfo> TelegraphNotifyInfo;
		if (Anim.GetAnimNotifyStateTriggerTimes(UBasicAITelegraphingAnimNotify, TelegraphNotifyInfo) && (TelegraphNotifyInfo.Num() > 0))
			AnticipationTime = TelegraphNotifyInfo[0].TriggerTime + TelegraphNotifyInfo[0].Duration;

		if (Durations.Telegraph < SMALL_NUMBER)
			Durations.Telegraph = Math::Min(AnticipationTime, ActionTime);
		if (Durations.Anticipation < SMALL_NUMBER)
			Durations.Anticipation = Math::Max(ActionTime - AnticipationTime, 0.01);
		if (Durations.Action < SMALL_NUMBER)
			Durations.Action = Math::Max(RecoveryTime - ActionTime, 0.01);
		if (Durations.Recovery < SMALL_NUMBER)
			Durations.Recovery = Math::Max(Anim.PlayLength - RecoveryTime, 0.01);
	}

	UAnimSequence GetRequestedAnimation(FName Tag, FName SubTag)
	{
		// Very little here so far...
		if (Tag == LocomotionFeatureAISkylineTags::EnforcerShooting)
		{
			ULocomotionFeatureEnforcerShooting Feature = Cast<ULocomotionFeatureEnforcerShooting>(Mesh.GetFeatureByClass(ULocomotionFeatureEnforcerShooting));
			if (SubTag == SubTagAIEnforcerShooting::ThrowGrenade)
				return Feature.AnimData.ThrowGrenade.Sequence;
			return nullptr; // The rest are blend spaces
		}
		return nullptr;
	}
};
