UCLASS(Abstract)
class UFeatureAnimInstanceRainbowPigLanding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRainbowPigLanding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRainbowPigLandingAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSiloMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUseSlopeRot = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UHazeMovementComponent MoveComp;
	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerPigSiloComponent PlayerPigSiloComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureRainbowPigLanding NewFeature = GetFeatureAsClass(ULocomotionFeatureRainbowPigLanding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		PlayerPigSiloComp = UPlayerPigSiloComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
		if (PrevLocomotionAnimationTag == n"AirMovement")
		{
        	return 0;
		}
		else
		{
			return 0.1;
		}
    }

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		bSiloMovement = PlayerPigSiloComp.IsSiloMovementActive();

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.1);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}
		
		if (TopLevelGraphRelevantStateName == n"LandStill" && bWantsToMove)
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
