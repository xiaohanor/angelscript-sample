UCLASS(Abstract)
class UFeatureAnimInstanceTreeGuardianDistanceInteract : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardianDistanceInteract Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardianDistanceInteractAnimData AnimData;

	UTundraPlayerTreeGuardianComponent TreeComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendSpaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnterScrubbingDone;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float TimeSinceStart = 0.0;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTreeGuardianDistanceInteract NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardianDistanceInteract);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		TreeComponent = UTundraPlayerTreeGuardianComponent::Get(HazeOwningActor.AttachParentActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendSpaceValues.X = TreeComponent.LifeGiveAnimData.LifeGivingHorizontalAlpha;
		BlendSpaceValues.Y = TreeComponent.LifeGiveAnimData.LifeGivingVerticalAlpha;
		TimeSinceStart = TreeComponent.LifeGiveAnimData.AnimationScrubTime;
		bExit = TreeComponent.LifeGiveAnimData.bShouldExit;
	}
}
