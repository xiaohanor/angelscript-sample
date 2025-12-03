UCLASS(Abstract)
class UFeatureAnimInstancePrisonGuard : UAnimInstanceAIBase
{
	// We want to be able to extract root motion from everything; movement capability ensures that it's applied properly
	default RootMotionMode = ERootMotionMode::RootMotionFromEverything;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePrisonGuardAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EPrisonGuardAnimationRequest Request;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MovementPlayRate = 1.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SpineYaw = 0.0;

	UPrisonGuardAnimationComponent GuardAnimComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		if (HazeOwningActor != nullptr)
			GuardAnimComp = UPrisonGuardAnimationComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTimeX)
	{
		Super::BlueprintUpdateAnimation(DeltaTimeX);
		
		if (GuardAnimComp == nullptr)
			return;
		Request = GuardAnimComp.Request;	
		MovementPlayRate = GuardAnimComp.MovementPlayRate;
		SpineYaw = GuardAnimComp.AccSpineYaw.Value;
	}
}

