UCLASS(Abstract)
class UFeatureAnimInstanceHarp : UHazeFeatureSubAnimInstance
{
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHarp Feature;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHarpAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayReady;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccessThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFailedThisTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	bool bSuccess;
	bool bFail;

	UMoonGuardianHarpPlayingComponent HarpComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...
		HarpComp = UMoonGuardianHarpPlayingComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHarp NewFeature = GetFeatureAsClass(ULocomotionFeatureHarp);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		if (HarpComp == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		bExit = !HarpComp.bIsActive;
		bPlayReady = HarpComp.NoteTimer / HarpComp.CurrentNoteDuration > 0.2;

		bSuccessThisTick = CheckValueChangedAndSetBool(bSuccess, HarpComp.bNoteSucceeded, EHazeCheckBooleanChangedDirection::FalseToTrue);
		bFailedThisTick = CheckValueChangedAndSetBool(bFail, HarpComp.bNoteFailed || (!HarpComp.bLastNoteSucceeded && !bPlayReady), EHazeCheckBooleanChangedDirection::FalseToTrue);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
