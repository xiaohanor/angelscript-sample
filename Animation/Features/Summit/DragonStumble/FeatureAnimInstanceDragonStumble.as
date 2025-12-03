UCLASS(Abstract)
class UFeatureAnimInstanceDragonStumble : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDragonStumble Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDragonStumbleAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection Direction;

	float Duration = 1.0;

	UTeenDragonStumbleComponent StumbleComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		// Get components here...
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDragonStumble NewFeature = GetFeatureAsClass(ULocomotionFeatureDragonStumble);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
		if (HazeOwningActor == nullptr)
			return; // Editor preview
		ATeenDragon Dragon = Cast<ATeenDragon>(OwningComponent.Owner);
		if(Dragon == nullptr)
			return;

		StumbleComp = UTeenDragonStumbleComponent::Get(OwningComponent.Owner);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		if (HazeOwningActor == nullptr)
			return; // Editor preview
		if(StumbleComp == nullptr)
			return;

		Direction = StumbleComp.AnimData.Direction;
		Duration = StumbleComp.AnimData.Duration;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance) {}

	UFUNCTION(BlueprintPure, meta = (BlueprintThreadSafe))
	float GetStumblePlayRate(FHazePlaySequenceData Data)
	{
		if (Duration > 0.0 && Data.Sequence != nullptr)
			return Data.Sequence.PlayLength / Duration;
		return 1.0;
	}
}
