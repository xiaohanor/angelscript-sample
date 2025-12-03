UCLASS(Abstract)
class UFeatureAnimInstanceTreeGuardianWalkingstickInteract : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTreeGuardianWalkingstickInteract Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTreeGuardianWalkingstickInteractAnimData AnimData;
	
	UTundraPlayerTreeGuardianComponent TreeComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendSpaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMoving;

	UHazeMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FTundraPlayerTreeGuardianLifeGiveAnimData LifeGiveAnimData;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTreeGuardianWalkingstickInteract NewFeature = GetFeatureAsClass(ULocomotionFeatureTreeGuardianWalkingstickInteract);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		TreeComponent = UTundraPlayerTreeGuardianComponent::Get(HazeOwningActor.AttachParentActor);

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor.AttachParentActor);
	}

		UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bIsMoving = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		BlendSpaceValues.X = TreeComponent.LifeGiveAnimData.LifeGivingHorizontalAlpha;
		BlendSpaceValues.Y = TreeComponent.LifeGiveAnimData.LifeGivingVerticalAlpha;

		bExit = TreeComponent.LifeGiveAnimData.bShouldExit;
		LifeGiveAnimData = TreeComponent.LifeGiveAnimData;
	}
}
