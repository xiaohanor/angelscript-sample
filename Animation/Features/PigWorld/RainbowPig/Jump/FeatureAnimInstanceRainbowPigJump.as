UCLASS(Abstract)
class UFeatureAnimInstanceRainbowPigJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRainbowPigJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRainbowPigJumpAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUseSlopeRot = true;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerPigSiloComponent PlayerPigSiloComp;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		PlayerPigSiloComp = UPlayerPigSiloComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureRainbowPigJump NewFeature = GetFeatureAsClass(ULocomotionFeatureRainbowPigJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0.1;
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.3);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"AirMovement")
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
