enum EAnimExosuitOverrideFilter
{
	NONE,
	ShoulderOnly,
	Activate,
	Activated
}

class UAnimInstanceZoeExoSuitPostProcess : UAnimInstance
{
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData CutsceneMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Activate;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ActivateMh;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FName LocomotionAnimationTag;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HairPhysicsAlpha;

	UPROPERTY(BlueprintReadOnly)
	TArray<FName> OverrideArmsAnimationTags;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bValidAnimTag;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCharge;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float OverrideAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EAnimExosuitOverrideFilter Filter = EAnimExosuitOverrideFilter::NONE;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsControlledByCutscene;

	UMagneticFieldPlayerComponent PlayerComp;
	UHazeCharacterAnimInstance BaseAnimInstance;

	AHazeActor HazeOwningActor;

	FName TopLevelStateNameCached;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		HazeOwningActor = Cast<AHazeActor>(OwningComponent.GetOwner());
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		if (HazeOwningActor == nullptr || !HazeOwningActor.IsA(AHazePlayerCharacter))
			return;

		PlayerComp = UMagneticFieldPlayerComponent::Get(HazeOwningActor);
		BaseAnimInstance = Cast<UHazeCharacterAnimInstance>(OwningComponent.GetAnimInstance());
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (PlayerComp == nullptr)
		{
			if (HazeOwningActor != nullptr)
				PlayerComp = UMagneticFieldPlayerComponent::Get(HazeOwningActor);

			return;
		}

		bCharge = PlayerComp.GetChargeState() != EMagneticFieldChargeState::None;

		LocomotionAnimationTag = BaseAnimInstance.GetLocomotionAnimationTag();
		TopLevelStateNameCached = TopLevelGraphRelevantStateName;
		bIsControlledByCutscene = HazeOwningActor.bIsControlledByCutscene;

		OverrideAlpha = PlayerComp.AnimOverrideCutsceneAlpha;
	}

	UFUNCTION(BlueprintOverride, Meta = (BlueprintThreadSafe))
	void BlueprintThreadSafeUpdateAnimation(float DeltaTime)
	{
		if (bIsControlledByCutscene)
		{
			Filter = EAnimExosuitOverrideFilter::ShoulderOnly;
			HairPhysicsAlpha = 0.4;
		}
		else if (bCharge)
		{
			HairPhysicsAlpha = 0;
			bValidAnimTag = OverrideArmsAnimationTags.Contains(LocomotionAnimationTag);
			if (bValidAnimTag)
			{
				if (TopLevelStateNameCached == n"ActivateMH" || TopLevelStateNameCached == n"ActivateNoArmsMH")
					Filter = EAnimExosuitOverrideFilter::Activated;
				else
					Filter = EAnimExosuitOverrideFilter::Activate;
			}
			else
				Filter = EAnimExosuitOverrideFilter::ShoulderOnly;
		}
		else
		{
			Filter = EAnimExosuitOverrideFilter::ShoulderOnly;
			bValidAnimTag = false;
			HairPhysicsAlpha = 0;
		}
	}
}