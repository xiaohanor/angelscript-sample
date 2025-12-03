UFUNCTION(BlueprintCallable)
mixin void RequestPlayerStress(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerEffortAudioComponent EffortAudioComponent = UPlayerEffortAudioComponent::Get(Player);
	if(EffortAudioComponent != nullptr)
	{
		EffortAudioComponent.AddStressInstigator(Instigator);
	}
}

UFUNCTION(BlueprintCallable)
mixin void UnRequestPlayerStress(AHazePlayerCharacter Player, FInstigator Instigator)
{
	UPlayerEffortAudioComponent EffortAudioComponent = UPlayerEffortAudioComponent::Get(Player);
	if(EffortAudioComponent != nullptr)
	{
		EffortAudioComponent.RemoveStressInstigator(Instigator);
	}
}

UFUNCTION(BlueprintPure)
mixin bool PlayerIsInStress(AHazePlayerCharacter Player)
{
	UPlayerEffortAudioComponent EffortAudioComponent = UPlayerEffortAudioComponent::Get(Player);
	if(EffortAudioComponent != nullptr)
	{
		return EffortAudioComponent.IsStressed();
	}

	return false;
}

class UPlayerEffortAudioComponent : UActorComponent
{		
	default Recoveries.SetNum(int(EEffortAudioIntensity::EEffortAudioIntensity_MAX) - 1);

	UPROPERTY(EditDefaultsOnly)
	UPlayerEffortAudioSettings EffortsAsset;

	// Current exertion factor
	private float Exertion = 0.0;
	float EffortTarget = 0.0;
	float RecoveryTarget = 0.0;

	private FEffortData CurrentEffort;
	private FEffortData PreviousEffort;
	private TArray<FRecoveryEffortDatas> Recoveries;

	private TArray<FInstigator> StressInstigators;

	private FName LastTag = NAME_None;
	private int32 HighestEffortCategory = int(EEffortAudioIntensity::None);

	private float EffortActivationTimestamp = 0.0;
	private bool bEffortsGroupIsIdle = false;

	const FName PLAYER_EFFORTS_GROUP_NAME = n"Player_Efforts";

	bool bIsRecovering = false;
	bool bHasValidEffort = false;
	bool bIsInOpenMouthBreathingCycle = false;

	access InternalWithCapability = private, UPlayerEffortAudioCapability, UPlayerEffortRecoveryAudioCapability;
	access InternalWithEffort = private, UPlayerEffortAudioCapability;
	access InternalWithRecovery = private, UPlayerEffortRecoveryAudioCapability;
	access:InternalWithCapability
	float EffortCurveAlpha = 0; 

	access:InternalWithCapability
	float RecoveryCurveAlpha = 0; 

	access:InternalWithCapability
	void SetEffortCurveAlpha(const float InValue, const float Max = 1)
	{
		EffortCurveAlpha = Math::Clamp(EffortCurveAlpha + (InValue / 100), 0.0, Max);
		RecoveryCurveAlpha = 1 - EffortCurveAlpha;
	}

	access:InternalWithCapability
	void SetRecoveryCurveAlpha(const float InValue)
	{
		RecoveryCurveAlpha = Math::Clamp(RecoveryCurveAlpha + (InValue / 100), 0.0, 1.0);
		EffortCurveAlpha = 1 - RecoveryCurveAlpha;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(GetOwner());
		UHazeMovementAudioComponent MoveAudioComp = UHazeMovementAudioComponent::Get(PlayerOwner);

		MoveAudioComp.OnMovementTagChanged.AddUFunction(this, n"OnMovementTagChanged");

		UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(PlayerOwner);
		HealthComp.OnReviveTriggered.AddUFunction(this, n"OnPlayerRespawn");
		
		if(EffortsAsset != nullptr)
			PlayerOwner.ApplyDefaultSettings(EffortsAsset);		
	}

	float GetExertion() const
	{
		return Exertion;
	}

	float GetExertionFactorMultiplier(bool bRecovery = false)
	{
		if(bRecovery)
			return Math::Lerp(EffortsAsset.EffortCurveMaxMultiplier, EffortsAsset.EffortCurveMinMultiplier, Math::Max(Exertion, 0.001) / GetEffortMaxClampValue(CurrentEffort));

		return Math::Lerp(EffortsAsset.EffortCurveMinMultiplier, EffortsAsset.EffortCurveMaxMultiplier, Math::Max(Exertion, 0.001) / GetEffortMaxClampValue(CurrentEffort));
	}

	void IncrementExertion(const float Increment)
	{		
		float Delta = Increment - EffortTarget;
		Delta = Math::Max(Delta, 0.0);

		const float ClampValue = GetEffortMaxClampValue(CurrentEffort);
		Exertion = Math::Min(Exertion + Delta, ClampValue);
		EffortTarget += Delta;
	}

	access:InternalWithCapability
	void SetEffortExertion(const float NewTarget, const float DeltaTime = 1.0)
	{
		float Delta = NewTarget - Exertion;
		Delta = Math::Max(Delta, 0.0);

		EffortTarget = Math::Min(EffortTarget + Delta, GetEffortMaxClampValue(CurrentEffort));
		SetExertion(DeltaTime);
	}

	access:InternalWithRecovery
	void SetRecoveryExertion(const float NewTarget, const float DecrementedEffort, const float DeltaTime = 1.0)
	{
		EffortTarget = NewTarget;
		EffortTarget = Math::Max(0.0, EffortTarget);

		RecoveryTarget = NewTarget;
		RecoveryTarget = Math::Max(0.0, RecoveryTarget);
		SetExertion(DeltaTime);	
	}

	private void SetExertion(const float DeltaTime)
	{		
		const float ExertionTarget = bIsRecovering ? Math::Max(EffortTarget, RecoveryTarget) : EffortTarget;
		Exertion = Math::Clamp(Math::FInterpConstantTo(Exertion, ExertionTarget, DeltaTime, 10), 0.0, 100.0);
	}

	void DecrementExertion(const float Decrement)
	{
		Exertion = Math::Max(Exertion + (-Decrement), 0.0);	
	}
	
	void PushEffortData(const FName& InGroup, const FName& InTag)
	{
		if(EffortsAsset == nullptr)
			return;

		FEffortData EffortData;
		
		bool bFoundData = false;
		for(auto& Effort : EffortsAsset.Efforts)
		{
			if(Effort.Group != InGroup
			|| Effort.Tag != InTag)
				continue;

			bFoundData = true;
			EffortData = Effort;
			break;
		}

		if(!bFoundData)
			return;		

		PreviousEffort = CurrentEffort;
		CurrentEffort = EffortData;
		CurrentEffort.State = EEffortAudioState::Pending;

		QueryHighestEffort();

		if(PreviousEffort.State != EEffortAudioState::Consumed)
			ConsumeEffort(bWasCompleted = false);
		
		EffortActivationTimestamp = Time::GetGameTimeSeconds();
		bHasValidEffort = true;
	}

	void PushRecoveryData(bool bWasCompleted = false)
	{
		FEffortData WantedEffortData = bWasCompleted ? CurrentEffort : PreviousEffort;

		const bool bShouldRecover = WantedEffortData.Intensity != EEffortAudioIntensity::None;
		if(!bShouldRecover)
			return;

		WantedEffortData.State = EEffortAudioState::Consumed;
		Recoveries[int(WantedEffortData.Intensity) - 1].Data.Insert(WantedEffortData);
	}

	void ConsumeRecoveredEffort(FEffortData& Recovery)
	{
		Recovery.State = EEffortAudioState::Recovered;
		Recoveries[int(Recovery.Intensity) - 1].Data.RemoveAt(0);	
		QueryHighestEffort();
	}

	private void ClearRecoveries()
	{
		for(int i = int(EEffortAudioIntensity::EEffortAudioIntensity_MAX) - 2; i >= 0; --i)
		{
			Recoveries[i].Data.Empty();
		}

		CurrentEffort = FEffortData();
		Exertion = 0.0;
	}

	FEffortData& GetNextRecoveryData()
	{
		for(int i = int(EEffortAudioIntensity::EEffortAudioIntensity_MAX) - 2; i >= 0; --i)
		{
			TArray<FEffortData>& CurrDatas = Recoveries[i].Data;
			if(CurrDatas.Num() > 0)
			{
				return CurrDatas[0];
			}
		}

		return CurrentEffort;
	}

	bool IsRecovering() const
	{
		return bIsRecovering;
	}

	bool IsInEffortsIdleTag() const
	{
		return bEffortsGroupIsIdle;
	}

	FEffortData& GetCurrentEffortData()
	{
		return CurrentEffort;	
	}

	void QueryHighestEffort()
	{
		int32 HighestPendingRecovery = 0;

		for(int i = Recoveries.Num() - 1; i >= 0; --i)
		{
			if(Recoveries[i].Data.Num() > 0)
			{
				HighestPendingRecovery = i + 1;
				break;
			}
		}

		if(CurrentEffort.State == EEffortAudioState::Consumed && HighestPendingRecovery == 0)
		{
			HighestEffortCategory = 0;
			CurrentEffort.State = EEffortAudioState::Recovered;
		}
		else if(CurrentEffort.PushType == EEffortAudioPushType::Continuous)
		{
			HighestEffortCategory = Math::Max(HighestPendingRecovery, int(CurrentEffort.Intensity));
		}
		else
		{
			HighestEffortCategory = 0;
		}
	}

	int32 GetHighestEffortCategory()
	{
		return HighestEffortCategory;
	}

	float GetValueFromCurve(const FEffortData& EffortData, float& MaxClampRange)
	{
		const bool bIsEffort = EffortData.State == EEffortAudioState::Handling;

		UCurveFloat WantedCurve = bIsEffort ? EffortsAsset.EffortCurve : EffortsAsset.RecoveryCurve;
		float WantedCurveAlpha = bIsEffort ? EffortCurveAlpha : RecoveryCurveAlpha;

		const float RawCurveValue = WantedCurve.GetFloatValueNormalized(WantedCurveAlpha);
		const float ClampValue = bIsEffort ? GetEffortMaxClampValue(EffortData) : 100;	

		MaxClampRange = WantedCurve.GetFloatValueNormalized(ClampValue / 100);
		return RawCurveValue * 100;
	}

	float GetValueFromCurve(UCurveFloat WantedCurve, float CurveAlpha)
	{
		const float RawCurveValue = WantedCurve.GetFloatValueNormalized(CurveAlpha);
		return RawCurveValue * 100;
	}

	float GetEffortMaxClampValue(const FEffortData& EffortData) const
	{
		if(EffortsAsset != nullptr)
		{
			switch(EffortData.Intensity)
			{
				case(EEffortAudioIntensity::Low): return EffortsAsset.LowEffortThreshold;
				case(EEffortAudioIntensity::Medium): return EffortsAsset.MediumEffortThreshold;
				case(EEffortAudioIntensity::High): return EffortsAsset.HighEffortThreshold;
				case(EEffortAudioIntensity::Critical): return EffortsAsset.CriticalEffortThreshold;	
				default: return 0;				
			}
		}

		return 0;
	}

	float GetEffortTimeActive() const
	{
		if(CurrentEffort.Intensity == EEffortAudioIntensity::None)
			return -1.0;

		return Time::GetGameTimeSince(EffortActivationTimestamp);
	}

	bool HasPendingEffort() const
	{
		return CurrentEffort.Intensity != EEffortAudioIntensity::None
			&& CurrentEffort.Tag != NAME_None
			&& CurrentEffort.State == EEffortAudioState::Pending
			&& Exertion < GetEffortMaxClampValue(CurrentEffort);
	}

	bool HasPendingRecoveries() const
	{
		for(auto& RecoveryData : Recoveries)
		{
			if(RecoveryData.Data.Num() > 0)
				return true;
		}

		return false;
	}

	void ConsumeEffort(bool bWasCompleted = false)
	{			
		if(bWasCompleted)
			CurrentEffort.State = EEffortAudioState::Consumed;

		PushRecoveryData(bWasCompleted);		
	}

	UFUNCTION()
	void OnMovementTagChanged(FName Group, FName Tag, bool bIsEnter, bool bIsOverride)
	{
		if(bIsEnter)
		{
			PushEffortData(Group, Tag);
			LastTag = Tag;

			if(Group.IsEqual(PLAYER_EFFORTS_GROUP_NAME) && Tag.IsEqual(n"Idle"))
				bEffortsGroupIsIdle = true;
		}
		else if(IsGroupTracked(Group))
		{
			bHasValidEffort = false;

			if(Group.IsEqual(PLAYER_EFFORTS_GROUP_NAME) && Tag.IsEqual(n"Idle"))
				bEffortsGroupIsIdle = false;
		}
	}	

	bool IsGroupTracked(const FName Group)
	{
		if(EffortsAsset == nullptr)
			return false;

		for(auto& Effort : EffortsAsset.Efforts)
		{
			if(Effort.Group == Group)
				return true;
		}

		return false;
	}

	UFUNCTION()
	void OnPlayerRespawn()
	{
		ClearRecoveries();
	}

	void AddStressInstigator(FInstigator Instigator)
	{
		StressInstigators.AddUnique(Instigator);
	}

	void RemoveStressInstigator(FInstigator Instigator)
	{
		StressInstigators.RemoveSingleSwap(Instigator);
	}

	bool IsStressed() const
	{
		for(auto& Instigator : StressInstigators)
		{
			if(!Instigator.IsStale())
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintPure)
	bool IsInOpenMouthBreathingCycle()
	{
		return bIsInOpenMouthBreathingCycle;
	}

	#if EDITOR
	FString GetRecoveriesAsString() const
	{
		FString RecoveriesAsStr = "";

		for(int i = int(EEffortAudioIntensity::EEffortAudioIntensity_MAX) - 2; i >= 0; --i)
		{
			const TArray<FEffortData>& CurrDatas = Recoveries[i].Data;
			for(auto& Recovery : CurrDatas)
			{
				RecoveriesAsStr += f"{Recovery.Tag} - {Recovery.Intensity: n} - {Recovery.EffortTotal}\n";
			}
		}

		return RecoveriesAsStr;
	}

	void Debug_PushEffort(const float Amount)
	{
		auto DummyEffort = FEffortData();
		DummyEffort.EffortFactor = Amount;
		DummyEffort.Intensity = EEffortAudioIntensity::Low;
		DummyEffort.PushType = EEffortAudioPushType::Immediate;		

		PreviousEffort = CurrentEffort;
		CurrentEffort = DummyEffort;
		CurrentEffort.State = EEffortAudioState::Pending;

		QueryHighestEffort();
		
		EffortActivationTimestamp = Time::GetGameTimeSeconds();
		bHasValidEffort = true;
	}

	void Debug_RecoverEffort(const float Factor)
	{	
		CurrentEffort.EffortTotal = 0.0;	
		PushRecoveryData(bWasCompleted = true);
		Exertion = GetExertion() - Factor;
	}
	#endif
}