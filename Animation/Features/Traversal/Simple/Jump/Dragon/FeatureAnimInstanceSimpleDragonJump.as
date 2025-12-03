UCLASS(Abstract)
class UFeatureAnimInstanceSimpleDragonJump : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleDragonJump Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleDragonJumpAnimData AnimData;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsPlayer;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleDragonJump NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleDragonJump);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		auto Dragon = Cast<ATeenDragon>(HazeOwningActor);
		bIsPlayer = Dragon == nullptr;
		if (bIsPlayer)
		{
			SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		}
		else
		{
			SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(Dragon.DragonComponent.Owner);
		}
	
		SlopeAlignComp.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);

	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return 0;
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		if (!bIsPlayer)
		{
			SlopeOffset = Math::VInterpTo(SlopeOffset, FVector::ZeroVector, DeltaTime, 3);
			SlopeRotation = Math::RInterpTo(SlopeRotation, FRotator::ZeroRotator, DeltaTime, 3);
		}
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
