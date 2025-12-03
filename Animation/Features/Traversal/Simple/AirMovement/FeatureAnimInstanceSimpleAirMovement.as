UCLASS(Abstract)
class UFeatureAnimInstanceSimpleAirMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimpleAirMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimpleAirMovementAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UHazeMovementComponent MoveComp;
	FQuat CachedActorQuat;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimpleAirMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureSimpleAirMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return GetAnimFloatParam(n"MovementBlendTime", true, 0.2f);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendspaceValues.Y = HazeOwningActor.GetActorLocalVelocity().X;
		BlendspaceValues.X = CalculateAnimationBankingValue(HazeOwningActor, CachedActorQuat, DeltaTime, Feature.MaxTurnSpeed);
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
