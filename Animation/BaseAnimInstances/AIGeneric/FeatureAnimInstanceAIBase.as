
UCLASS(Abstract)
class UFeatureAnimInstanceAIBase : UHazeFeatureSubAnimInstance
{
	// Do not expose to blueprint, this should only be used on game thread
	UBasicAIAnimationComponent AnimComp;
	UBasicAIHealthComponent HealthComp;
	UHazeMovementComponent MoveComp;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	FName CurrentSubTag = NAME_None;

	UPROPERTY(BlueprintReadOnly)
	FName FinishedStateName = n"Finished";

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	bool bIsAiming = false;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	bool bIsMoving = false;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float SpeedForward = 0.0;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float SpeedRight = 0.0;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float SpeedUp = 0.0;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float ScaledPlayRate = 1.0;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	bool bIsInAir;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float TurnRate;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float PitchRate;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float AimPitch = 0.0;
	
	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float AimYaw = 0.0;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float LastDamageTime = 0.0;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	bool bHurtReactionThisTick = false;

	UPROPERTY(BlueprintReadOnly, Category = "Cached data")
	float HealthFraction = 1.0;


	UPROPERTY(Category = "NotifyDividers")
	TSubclassOf<UAnimNotifyState> TelegraphNotifyClass = UBasicAITelegraphingAnimNotify;

	UPROPERTY(Category = "NotifyDividers")
	TSubclassOf<UAnimNotifyState> ActionNotifyClass = UBasicAIActionAnimNotify;

	float PrevTookDamageTime;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if(HazeOwningActor != nullptr)
		{
			AnimComp = UBasicAIAnimationComponent::Get(HazeOwningActor);
			HealthComp = UBasicAIHealthComponent::Get(HazeOwningActor);
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		}

		if (HealthComp != nullptr)
		{
			LastDamageTime = HealthComp.LastDamageTime;
			PrevTookDamageTime = LastDamageTime;
		}
		
		if (MoveComp != nullptr)
		{
			bIsInAir = MoveComp.IsInAir();
		}
	}

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (AnimComp == nullptr) 
		{
#if EDITOR			
			// Should be editor preview
			devCheck((HazeOwningActor == nullptr) || !HazeOwningActor.World.IsGameWorld(), 
					  "AI SubABP " + Name + " on " + HazeOwningActor + " did not have an animation component in a game world!\n"
					  + "Make sure you call Super::BlueprintInitializeAnimation() in the child animinstance, or check with Anders!");
#endif					  
			return; 
		}

		CurrentSubTag = AnimComp.SubFeatureTag;
		bIsAiming = AnimComp.bIsAiming;
		bIsMoving = AnimComp.IsMoving();	
		SpeedForward = AnimComp.SpeedForward;
		SpeedRight = AnimComp.SpeedRight;
		SpeedUp = AnimComp.SpeedUp;
		TurnRate = AnimComp.TurnRate;
		PitchRate = AnimComp.PitchRate;
		ScaledPlayRate = 1.0 / OwningComponent.WorldScale.X;
		AimPitch = AnimComp.AimPitch.Get();
		AimYaw = AnimComp.AimYaw.Get();


		if (MoveComp != nullptr)
		{
			bIsInAir = MoveComp.IsInAir();
		}

		if (HealthComp != nullptr)
		{
			LastDamageTime = HealthComp.LastDamageTime;
			bHurtReactionThisTick = (LastDamageTime != PrevTookDamageTime) && HealthComp.IsAlive();
			PrevTookDamageTime = LastDamageTime;
			HealthFraction = HealthComp.GetHealthFraction();
		}

		UpdateActionDuration();
	}

	UFUNCTION(BlueprintOverride)
	void LogAnimationTemporalData(FTemporalLog& TemporalLog) const
	{
#if TEST
		TemporalLog.Value("Current SubTag", CurrentSubTag);
		TemporalLog.Value("Is Aiming", bIsAiming);
		TemporalLog.Value("Is Moving", bIsMoving);
		TemporalLog.Value("Speed Forward", SpeedForward);
		TemporalLog.Value("Speed Right", SpeedRight);
		TemporalLog.Value("Turn Rate", TurnRate);
		TemporalLog.Value("Pitch Rate", PitchRate);
		TemporalLog.Value("Aim Pitch", AimPitch);
		TemporalLog.Value("Aim Yaw", AimYaw);
#endif
	}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float GetActionPlayRate(FHazePlaySequenceData Data)
	{
		if(AnimComp == nullptr)
			return 1.0;
		return AnimComp.GetActionPlayRate(Data);
	}

	private float GetSequencePlayRate(UAnimSequenceBase Sequence)
	{
		return AnimComp.GetSequencePlayRate(Sequence);
	}

	void UpdateActionDuration()
	{
		if (!AnimComp.HasDurationRequest())
		{
			AnimComp.ActionPlayRate.Empty();
			return;
		}

		// TODO: No need to calculate this every update, should cache when we start playing new anim or change action duration instead
		AnimComp.ActionPlayRate.Empty();
		TArray<FHazePlayingAnimationData> AllAnimData;
		GetCurrentlyPlayingAnimations(AllAnimData);
		if (!AnimComp.HasActionDurationRequest())
		{
			// Flat playrate across the whole animation
			float RequestedDuration = Math::Max(0.1, AnimComp.GetDurationRequest());
			for (FHazePlayingAnimationData AnimData : AllAnimData)
			{
				if (AnimData.Sequence == nullptr)
					continue;
				AnimComp.ActionPlayRate.Add(AnimData.Sequence, AnimData.Sequence.ScaledPlayLength / RequestedDuration);
			}
			return;
		}
		
		// Specific playrates for the various parts of the animation 
		FBasicAIAnimationActionDurations ActionDurations = AnimComp.GetActionDurationRequest();
		for (FHazePlayingAnimationData AnimData : AllAnimData)
		{
			if (AnimData.Sequence == nullptr)
				continue;

			TArray<FHazeAnimNotifyStateGatherInfo> ActionNotifyInfo;
			if (!AnimData.Sequence.GetAnimNotifyStateTriggerTimes(ActionNotifyClass, ActionNotifyInfo) || (ActionNotifyInfo.Num() == 0))
			{
				// No action notify to split anim into parts, just use flat duration
				AnimComp.ActionPlayRate.Add(AnimData.Sequence, AnimData.Sequence.ScaledPlayLength / Math::Max(0.1, AnimComp.GetDurationRequest()));
				continue;
			}

			float AnimHitStart = ActionNotifyInfo[0].TriggerTime;
			float AnimRecoveryStart = ActionNotifyInfo.Last().TriggerTime + ActionNotifyInfo.Last().Duration;

			float AnimTelegraphDuration = 0.0;
			TArray<FHazeAnimNotifyStateGatherInfo> TelegraphNotifyInfo;
			if (AnimData.Sequence.GetAnimNotifyStateTriggerTimes(TelegraphNotifyClass, TelegraphNotifyInfo) && (TelegraphNotifyInfo.Num() > 0))
				AnimTelegraphDuration = Math::Min(TelegraphNotifyInfo[0].TriggerTime + TelegraphNotifyInfo[0].Duration, AnimHitStart);

			if(ActionDurations.Telegraph > 0)
				devCheck(AnimTelegraphDuration > 0, "Telegraph action duration has been set but no telegraph notify was found in animation data.");

			float AnimAnticipationDuration = AnimHitStart - AnimTelegraphDuration;
			float AnimHitDuration = AnimRecoveryStart - AnimHitStart;
			float AnimRecoveryDuration = AnimData.Sequence.ScaledPlayLength - AnimRecoveryStart;

			float PlayRate = 1.0;
			if (AnimData.CurrentPosition < AnimTelegraphDuration)
				PlayRate = AnimTelegraphDuration / Math::Max(ActionDurations.Telegraph, 0.1);
			else if (AnimData.CurrentPosition < AnimTelegraphDuration + AnimAnticipationDuration)
				PlayRate = AnimAnticipationDuration / Math::Max(ActionDurations.Anticipation, 0.1);
			else if (AnimData.CurrentPosition < AnimTelegraphDuration + AnimAnticipationDuration + AnimHitDuration)
				PlayRate = AnimHitDuration / Math::Max(ActionDurations.Action, 0.1);
			else
				PlayRate = AnimRecoveryDuration / Math::Max(ActionDurations.Recovery, 0.1);

			AnimComp.ActionPlayRate.Add(AnimData.Sequence, PlayRate);

#if EDITOR
			//OwningComponent.bHazeEditorOnlyDebugBool = true;
			if (OwningComponent.bHazeEditorOnlyDebugBool)
			{
				PrintToScreen( 
					"Telegraph:    " + AnimTelegraphDuration + " -> " + ActionDurations.Telegraph + "\n" + 
					"Anticipation: " + AnimAnticipationDuration + " -> " + ActionDurations.Anticipation + "\n" + 
					"Action:       " + AnimHitDuration + " -> " + ActionDurations.Action + "\n" + 
					"Recovery:     " + AnimRecoveryDuration + " -> " + ActionDurations.Recovery);				
				PrintToScreen("Playrate: " + PlayRate);
				if (AnimData.CurrentPosition < AnimTelegraphDuration)
					PrintToScreen("Telegraph");
				else if (AnimData.CurrentPosition < AnimTelegraphDuration + AnimAnticipationDuration)
					PrintToScreen("Anticipation");
				else if (AnimData.CurrentPosition < AnimTelegraphDuration + AnimAnticipationDuration + AnimHitDuration)
					PrintToScreen("Hit");
				else
					PrintToScreen("Recovery");
				PrintToScreen("Currentpos: " + AnimData.CurrentPosition);
			}
#endif
		}
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsCurrentSubTag(FName SubTag)
	{
		return CurrentSubTag == SubTag;
	}
}

