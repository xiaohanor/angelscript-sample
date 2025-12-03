UCLASS(Abstract)
class UFeatureAnimInstanceLedgeMantle : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureLedgeMantle Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureLedgeMantleAnimData AnimData;

	UPROPERTY()
	UPlayerLedgeMantleComponent MantleComp;

	UPROPERTY()
	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LedgeMantleStartTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerLedgeMantleAnimData MantleAnimData;
	
	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureLedgeMantle NewFeature = GetFeatureAsClass(ULocomotionFeatureLedgeMantle);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MantleComp = UPlayerLedgeMantleComponent::GetOrCreate(Player);
		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);

		LedgeMantleStartTime = GetAnimFloatParam(n"LedgeMantleStartTime", true, DefaultValue = 0);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		MantleAnimData = MantleComp.AnimData;
	}

	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
		if(MantleAnimData.State == EPlayerLedgeMantleState::AirborneLowEnter || MantleAnimData.State ==EPlayerLedgeMantleState::AirborneLowExit)
			return 0.1;
		else
	        return GetAnimFloatParam(n"LedgeMantleBlendTime", true, 0.2);
    }
	
	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == FeatureName::Movement || LocomotionAnimationTag == n"AirMovement" || LocomotionAnimationTag == n"Landing")
			return IsTopLevelGraphRelevantAnimFinished();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if(GetLowestLevelGraphRelevantStateName() == n"FromJumpToRun")
			SetAnimFloatParam (n"MovementBlendTime", Math::GetMappedRangeValueClamped(FVector2D(0, UPlayerFloorMotionSettings::GetSettings(Player).MaximumSpeed), FVector2D(0.3, 0.05), MoveComp.HorizontalVelocity.Size()));
		else
			SetAnimFloatParam (n"MovementBlendTime", 0.2f);
	}
}
