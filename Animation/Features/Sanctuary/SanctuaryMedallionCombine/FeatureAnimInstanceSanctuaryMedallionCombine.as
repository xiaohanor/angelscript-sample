UCLASS(Abstract)
class UFeatureAnimInstanceSanctuaryMedallionCombine : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSanctuaryMedallionCombine Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSanctuaryMedallionCombineAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SuccessAlpha;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float JumpProgressAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInFail = false;

	UMedallionPlayerMergeHighfiveJumpComponent JumpComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSanctuaryMedallionCombine NewFeature = GetFeatureAsClass(ULocomotionFeatureSanctuaryMedallionCombine);
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

		if (JumpComp == nullptr && HazeOwningActor != nullptr)
			JumpComp = UMedallionPlayerMergeHighfiveJumpComponent::GetOrCreate(HazeOwningActor);
		if (JumpComp == nullptr)
			return;

		bIsInFail = JumpComp.IsInHighfiveFail();
		JumpProgressAlpha = JumpComp.GetHighfiveJumpProgressAlpha();
		SuccessAlpha = JumpComp.HighfiveHoldAlpha;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return TopLevelGraphRelevantAnimTimeRemainingFraction <= 0.1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
