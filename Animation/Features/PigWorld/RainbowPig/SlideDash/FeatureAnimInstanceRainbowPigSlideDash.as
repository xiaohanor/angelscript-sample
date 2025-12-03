UCLASS(Abstract)
class UFeatureAnimInstanceRainbowPigSlideDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRainbowPigSlideDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRainbowPigSlideDashAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerPigSiloComponent PlayerPigSiloComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		PlayerPigSiloComp = UPlayerPigSiloComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureRainbowPigSlideDash NewFeature = GetFeatureAsClass(ULocomotionFeatureRainbowPigSlideDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.1);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (PlayerPigSiloComp != nullptr)
		{
			if (PlayerPigSiloComp.IsJumping())
				return true;

			if (PlayerPigSiloComp.IsTumbling())
				return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.1;
    }
}
