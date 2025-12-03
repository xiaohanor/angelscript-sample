UCLASS(NotBlueprintable, HideCategories = "Activation Cooking Tags AssetUserData Navigation ComponentTick Disable Rendering LOD")
class UGravityBikeWhipThrowableComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Aim")
	bool bAimDirection = false;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Throw")
	float ThrowAtTargetSpeed = 4000;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Throw")
	float ThrowHorizontalSpeed = 2000;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Throw")
	float ThrowVerticalSpeed = 2000;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Throw")
	float ThrownLifeTime = 8;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Throw")
	float ThrowArcHeightPerSecond = 400;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Hit")
	float HitDamage = 0.4;

	UPROPERTY(EditDefaultsOnly, Category = "Throwable|Hit")
	bool bDamageIsFraction = false;

	AHazeActor HazeOwner;
	UGravityBikeWhipGrabTargetComponent GrabTargetComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		GrabTargetComp = UGravityBikeWhipGrabTargetComponent::Get(Owner);
	}

	FHitResult ThrowTrace(TArray<AActor> IgnoredActors, FVector TraceStart, FVector TraceEnd) const
	{
		check(GrabTargetComp.GrabState == EGravityBikeWhipGrabState::Thrown || GrabTargetComp.GrabState == EGravityBikeWhipGrabState::Dropped);

		if(TraceStart.Equals(TraceEnd))
			return FHitResult();

		// Trace for overlaps in front while thrown
		FHazeTraceSettings Trace = Trace::InitChannel(ETraceTypeQuery::Visibility);
		Trace.UseLine();

		Trace.IgnoreActor(Owner);
		Trace.IgnoreActors(IgnoredActors);
		Trace.IgnorePlayers();
		Trace.IgnoreActor(GravityBikeSpline::GetGravityBike());

		return Trace.QueryTraceSingle(TraceStart, TraceEnd);
	}

	UFUNCTION(CrumbFunction)
	void CrumbOnThrowHit(FGravityBikeWhipThrowHitData HitData)
	{
		check(GrabTargetComp.GrabState == EGravityBikeWhipGrabState::Thrown || GrabTargetComp.GrabState == EGravityBikeWhipGrabState::Dropped);

		if(!ensure(IsValid(HitData.HitActor)))
			return;

		// Deal damage to hit enemies
		auto EnemyHealthComp = UGravityBikeSplineEnemyHealthComponent::Get(HitData.HitActor);
		if(EnemyHealthComp != nullptr)
		{
			FGravityBikeSplineEnemyTakeDamageData DamageData(
				EGravityBikeSplineEnemyDamageType::Throwable,
				HitDamage,
				bDamageIsFraction,
				Owner.ActorVelocity.GetSafeNormal()
			);
			
			EnemyHealthComp.TakeDamage(DamageData);
		}

		FGravityBikeWhipThrowableHitEventData EventData(HitData);
		UGravityBikeWhipThrowableEventHandler::Trigger_OnThrowHit(HazeOwner, EventData);

		TriggerImpactAudio();

		// Destroy ourselves
		Owner.DestroyActor();
	}

	void TriggerImpactAudio()
	{
		auto AudioData = GrabTargetComp.AudioData;
		if(AudioData.bAudioObject && AudioData.ImpactEvent != nullptr)
		{
			FHazeAudioFireForgetEventParams Params;
			Params.AttenuationScaling = AudioData.AttenuationScaling;
			Params.Transform = Owner.ActorTransform;			

			Params.RTPCs.Reserve(3);
	
			auto MakeUpGainId = AudioData.GravityWhipTargetMakeUpGainRtpc;
			Params.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID(MakeUpGainId), AudioData.MakeUpGain));	

			auto VoiceVolumeId = AudioData.GravityWhipTargetVoiceVolumeRtpc;
			Params.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID(VoiceVolumeId), AudioData.VoiceVolume));
		
			auto PitchId = AudioData.GravityWhipTargetPitchRtpc;			
			Params.RTPCs.Add(FHazeAudioRTPCParam(FHazeAudioID(PitchId), AudioData.Pitch));	
		
			AudioComponent::PostFireForget(GrabTargetComp.AudioData.ImpactEvent, Params);
		}
	}

	UFUNCTION(BlueprintPure)
	bool WasDropped() const
	{
		return GrabTargetComp.GrabState == EGravityBikeWhipGrabState::Dropped;
	}

	UFUNCTION(BlueprintPure)
	bool WasThrown() const
	{
		return GrabTargetComp.GrabState == EGravityBikeWhipGrabState::Thrown;
	}
};