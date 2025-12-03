
struct FWalkerBossFeetEmitterData
{
	UPROPERTY(BlueprintReadOnly)
	UHazeAudioEmitter Emitter = nullptr;

	UPROPERTY(BlueprintReadOnly)
	float Speed = 0;

	UPROPERTY(BlueprintReadOnly)
	float Height = 0;

	FVector CachedLocation;
}

UCLASS(Abstract)
class UGameplay_Character_Boss_Island_Walker_Movement_Feet_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadOnly)
	AAIIslandWalker Walker;

	private TArray<FName> FeetSocketNames;
	default FeetSocketNames.Add(n"LeftBackMiddleLeg6");
	default FeetSocketNames.Add(n"LeftBackLeg6");
	default FeetSocketNames.Add(n"LeftFrontMiddleLeg5");
	default FeetSocketNames.Add(n"LeftFrontLeg5");
	default FeetSocketNames.Add(n"RightBackMiddleLeg6");
	default FeetSocketNames.Add(n"RightBackLeg6");
	default FeetSocketNames.Add(n"RightFrontMiddleLeg5");
	default FeetSocketNames.Add(n"RightFrontLeg5");

	UPROPERTY(BlueprintReadOnly)
	TArray<FWalkerBossFeetEmitterData> FeetEmitterDatas;	

	const float MAX_TRACKED_FEET_SPEED = 2000;

	UPROPERTY(BlueprintReadOnly)
	float ArenaHeight = 0.0;

	UPROPERTY(EditDefaultsOnly)
	float AttenuationScaling = 16000;

	UFUNCTION(BlueprintEvent)
	void TickFeet(const FWalkerBossFeetEmitterData& FeetEmitterData, float DeltaSeconds) {}

	UFUNCTION(BlueprintEvent)
	void OnFootDestroyed(const int Index) {}
	UFUNCTION(NotBlueprintCallable)
	private void OnWalkerFootDestroyed(AIslandWalkerLegTarget Leg)
	{
		const int LegIndex = Walker.LegsComp.LegTargets.FindIndex(Leg);
		OnFootDestroyed(LegIndex);
	}

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Walker = Cast<AAIIslandWalker>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Walker.PhaseComp.Phase < EIslandWalkerPhase::IntroEnd)
			return false;

		if(Walker.WalkerComp.bSuspended)
			return false;

		if(Walker.LegsComp.bIsUnbalanced)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return Walker.LegsComp.bIsUnbalanced == true;
	}

	private void CreateFeetEmitters()
	{
		for(auto Socket : FeetSocketNames)
		{
			FHazeAudioEmitterAttachmentParams AttachParams;
			AttachParams.Attachment = Walker.Mesh;
			AttachParams.BoneName = Socket;
			#if TEST
			AttachParams.EmitterName = FName(f"Character_Boss_Island_Walker_Movement_Feet_{Socket.ToString().LeftChop(1)}_Emitter");
			#endif
			AttachParams.Instigator = this;
			AttachParams.Owner = this;
			AttachParams.bCanAttach = true;

			auto Emitter = Audio::GetPooledEmitter(AttachParams);
			Emitter.AudioComponent.SetRelativeRotation(FRotator(90, 0.0, 0.0));
			Emitter.SetAttenuationScaling(AttenuationScaling);

			FWalkerBossFeetEmitterData EmitterData;
			EmitterData.Emitter = Emitter;

			FeetEmitterDatas.Add(EmitterData);
		}
	}

	private void ReleaseFeetEmitters()
	{
		for(auto& EmitterData : FeetEmitterDatas)
			Audio::ReturnPooledEmitter(this, EmitterData.Emitter);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		ArenaHeight = Walker.WalkerComp.ArenaLimits.Height;
		CreateFeetEmitters();

		Walker.LegsComp.OnLegDestroyed.AddUFunction(this, n"OnWalkerFootDestroyed");
	}

	private void UpdateFeetEmitterData(FWalkerBossFeetEmitterData&in EmitterData, float DeltaSeconds)
	{
		const FVector CurrentLocation = EmitterData.Emitter.GetEmitterLocation();
		EmitterData.Speed = (CurrentLocation - EmitterData.CachedLocation).Size() / DeltaSeconds;
		EmitterData.CachedLocation = CurrentLocation;
		EmitterData.Height = CurrentLocation.Z;

		TickFeet(EmitterData, DeltaSeconds);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(auto& FeetEmitterData : FeetEmitterDatas)
			UpdateFeetEmitterData(FeetEmitterData, DeltaSeconds);

		Log();
	}

	private void Log() 
	{
#if TEST
		TArray<FLinearColor> Debug_FeetColors;
		Debug_FeetColors.Add(FLinearColor(1.00, 0.00, 0.00));
		Debug_FeetColors.Add(FLinearColor(0.80, 0.65, 0.00));
		Debug_FeetColors.Add(FLinearColor(0.38, 0.68, 0.00));
		Debug_FeetColors.Add(FLinearColor(0.00, 0.97, 0.80));
		Debug_FeetColors.Add(FLinearColor(0.00, 0.15, 0.81));
		Debug_FeetColors.Add(FLinearColor(0.55, 0.00, 1.00));
		Debug_FeetColors.Add(FLinearColor(0.53, 0.04, 0.24));
		Debug_FeetColors.Add(FLinearColor(0.01, 0.00, 0.01));

		auto Log = TEMPORAL_LOG(Walker, "Audio/Feet");

		for(int i = 0; i < 8; ++i)
		{
			FVector EmitterLocation = FeetEmitterDatas[i].Emitter.GetEmitterLocation();
			Log.Circle(FeetSocketNames[i].ToString().LeftChop(1), EmitterLocation, 25.f, Color = Debug_FeetColors[i], LineWeight = 10.0);
			Log.Value(f"{FeetSocketNames[i].ToString().LeftChop(1)} Height:", FeetEmitterDatas[i].Emitter.AudioComponent.WorldLocation.Z);
			Log.Value(f"{FeetSocketNames[i].ToString().LeftChop(1)} Speed:", FeetEmitterDatas[i].Speed);
		}
#endif
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ReleaseFeetEmitters();
	}
}