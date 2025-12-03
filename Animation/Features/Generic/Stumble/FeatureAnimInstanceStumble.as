UCLASS(Abstract)
class UFeatureAnimInstanceStumble : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStumble Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStumbleAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInAir = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection Direction;

	float Duration = 1.0;

	UPlayerStumbleComponent StumbleComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStumble NewFeature = GetFeatureAsClass(ULocomotionFeatureStumble);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		StumbleComp = UPlayerStumbleComponent::Get(OwningComponent.Owner);
		MoveComp = UPlayerMovementComponent::Get(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Direction = StumbleComp.AnimData.Direction;
		Duration = StumbleComp.AnimData.Duration;

		if(MoveComp != nullptr)
			bIsInAir = MoveComp.IsInAir();
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

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float GetStumblePlayRate(FHazePlaySequenceData Data)
	{
		if (Duration > 0.0 && Data.Sequence != nullptr)
			return Data.Sequence.PlayLength / Duration;
		return 1.0;
	}
}
