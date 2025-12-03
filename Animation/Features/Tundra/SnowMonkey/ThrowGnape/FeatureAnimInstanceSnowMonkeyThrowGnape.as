UCLASS(Abstract)
class UFeatureAnimInstanceSnowMonkeyThrowGnape : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowMonkeyThrowGnape Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowMonkeyThrowGnapeAnimData AnimData;

	UPlayerSnowMonkeyThrowGnapeComponent ThrowGnapeComp;
	UPlayerMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsThrowing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowMonkeyThrowGnape NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowMonkeyThrowGnape);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		ThrowGnapeComp = UPlayerSnowMonkeyThrowGnapeComponent::Get(HazeOwningActor.AttachParentActor);
		MoveComp = UPlayerMovementComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		if (ThrowGnapeComp == nullptr)
			return; 

		bIsThrowing = ThrowGnapeComp.bThrow;

		Speed = MoveComp.Velocity.Size();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
			return true;

		if (!MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero())
			return true;

		return IsTopLevelGraphRelevantAnimFinished();
	}
}
