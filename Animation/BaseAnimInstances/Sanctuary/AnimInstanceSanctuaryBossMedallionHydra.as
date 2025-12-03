
enum EFeatureTagMedallionHydra
{
	None_Idling,

	Submerge,
	Emerge,
	BiteUnder,
	Roar,
	Bite,

	WaveAttack,
	RainAttack,
	ProjectileSingle,
	ProjectileTripple,
	ProjectileFlying,
	MachineGun,
	LaserOver,
	LaserForward,
	Death,
	StrangleStruggle,
	Cheerlead,

	BallistaAggro,
	BallistaAggroCanceled,
	BallistaAggroDeath,

	MeteorSpawn,
	MeteorFire
}

enum EFeatureSubTagMedallionHydra
{
	None,

	PreStart,
	Start,
	Mh,
	Action,
	End,
}

class UAnimInstanceSanctuaryBossMedallionHydra : UHazeAnimInstanceBase
{
	UPROPERTY(BlueprintReadOnly)
	FLocomotionFeatureBossMedallionHydraAnimData MedallionAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTransform HeadTargetTransform;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LookAtAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float PlayerFlyingCloserAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bShouldRandomizeIdleStart = true;

	USanctuaryBossMedallionHydraAnimComponent AnimComp;
	ASanctuaryBossMedallionHydra MedallionHydra;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor != nullptr)
		{
			MedallionHydra = Cast<ASanctuaryBossMedallionHydra>(HazeOwningActor);
			if (MedallionHydra != nullptr && MedallionHydra.LocomotionFeature != nullptr)
				MedallionAnimData = Cast<ASanctuaryBossMedallionHydra>(HazeOwningActor).LocomotionFeature.MedallionAnimData;
			AnimComp = USanctuaryBossMedallionHydraAnimComponent::GetOrCreate(HazeOwningActor);
			bShouldRandomizeIdleStart = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (MedallionHydra == nullptr)
			return;
		HeadTargetTransform = MedallionHydra.HeadPivot.WorldTransform;
		LookAtAlpha = MedallionHydra.HeadPivotLookAlpha;
		PlayerFlyingCloserAlpha = MedallionHydra.AnimPlayerFlyingCloserAlpha;

#if EDITOR
		// add more values if you wish :)
		TEMPORAL_LOG(MedallionHydra, "Animation (SkeletalMesh)").Value("Phase", AnimComp.GetFeatureTag());
		TEMPORAL_LOG(MedallionHydra, "Animation (SkeletalMesh)").Value("SubTag", AnimComp.GetSubFeatureTag());
		TEMPORAL_LOG(MedallionHydra, "Animation (SkeletalMesh)").Value("HeadPivotAlpha", LookAtAlpha);
		TEMPORAL_LOG(MedallionHydra, "Animation (SkeletalMesh)").Value("RandomizeIdleStart", bShouldRandomizeIdleStart);
#endif
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsCurrentSubTag(EFeatureSubTagMedallionHydra SubTag)
	{
		if (AnimComp != nullptr)
			return AnimComp.GetSubFeatureTag() == SubTag;
		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsCurrentFeatureTag(EFeatureTagMedallionHydra FeatureTag)
	{
		if (AnimComp != nullptr)
			return AnimComp.GetFeatureTag() == FeatureTag;
		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsNotCurrentFeatureTag(EFeatureTagMedallionHydra FeatureTag)
	{
		if (AnimComp != nullptr)
			return AnimComp.GetFeatureTag() != FeatureTag;
		return true;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	float GetCustomPlayRate() const
	{
		if (AnimComp != nullptr)
			return AnimComp.GetCustomPlayRate();
		return 1.0;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	float GetStruggleBlendspaceAlpha() const
	{
		if (AnimComp != nullptr)
			return AnimComp.CachedMioZoeStrangleAlpha;
		return 0.0;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool AnyPlayerFlying()
	{
		if (AnimComp != nullptr)
			return AnimComp.AnyPlayerFlying();
		return false;
	}

	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsInBallistaPhase()
	{
		if (AnimComp != nullptr)
			return AnimComp.IsInBallistaPhase();
		return false;
	}
	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	bool IsDead()
	{
		if (MedallionHydra != nullptr)
			return MedallionHydra.bDead;
		return false;
	}

	UFUNCTION()
	void AnimNotify_EnteredIdle()
	{
		bShouldRandomizeIdleStart = false;
	}
}
