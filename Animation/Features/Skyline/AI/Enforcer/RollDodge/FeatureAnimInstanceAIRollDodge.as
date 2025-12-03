UCLASS(Abstract)
class UFeatureAnimInstanceAIRollDodge : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAIRollDodge Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAIRollDodgeAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector RollDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection RollCardinalDirection;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		ULocomotionFeatureAIRollDodge NewFeature = GetFeatureAsClass(ULocomotionFeatureAIRollDodge);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Get roll direction
		// TODO: If this becomes a blendspace we might want to update this on tick //ns
		RollDirection = AnimComp.HasMovementRequest() ? AnimComp.GetMovementRequest() : HazeOwningActor.GetActorLocalVelocity();
		RollDirection.Normalize();
		const float Angle = FRotator::MakeFromXZ(RollDirection, HazeOwningActor.ActorUpVector).Yaw;
		RollCardinalDirection = AngleToCardinalDirection(Angle);
		
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);
		if (Feature == nullptr)
			return;
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
