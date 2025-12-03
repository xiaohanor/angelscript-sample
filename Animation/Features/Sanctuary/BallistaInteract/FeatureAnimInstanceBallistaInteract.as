UCLASS(Abstract)
class UFeatureAnimInstanceBallistaInteract : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBallistaInteract Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBallistaInteractAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float LeverTurnProgress;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BallistaRotationSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsStruggling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFinished;

	USanctuaryHydraKillerBallistaPlayerAnimationComponent OwnerBallistaAnimComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIK;

	UAnimFootTraceComponent FootTraceComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBallistaInteract NewFeature = GetFeatureAsClass(ULocomotionFeatureBallistaInteract);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		FootTraceComp = UAnimFootTraceComponent::Get(HazeOwningActor);
		if (FootTraceComp != nullptr)
			FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		if (OwnerBallistaAnimComp == nullptr)
			OwnerBallistaAnimComp = USanctuaryHydraKillerBallistaPlayerAnimationComponent::GetOrCreate(HazeOwningActor);
		
		if (OwnerBallistaAnimComp == nullptr)
			return;

		LeverTurnProgress = 1.0 - OwnerBallistaAnimComp.LeverTurnProgress;
		BallistaRotationSpeed = OwnerBallistaAnimComp.BallistaRotationSpeed;
		bIsStruggling = OwnerBallistaAnimComp.bIsStruggling;
		bIsFinished = OwnerBallistaAnimComp.bIsFinished;

		TEMPORAL_LOG(HazeOwningActor, "BallistaInteractAnim").Value("LeverTurnProgress", LeverTurnProgress);
		TEMPORAL_LOG(HazeOwningActor, "BallistaInteractAnim").Value("BallistaRotationSpeed", BallistaRotationSpeed);
		TEMPORAL_LOG(HazeOwningActor, "BallistaInteractAnim").Value("bIsStruggling", bIsStruggling);
		TEMPORAL_LOG(HazeOwningActor, "BallistaInteractAnim").Value("bIsFinished", bIsFinished);

		FootTraceComp.TraceFeet(IKFeetPlacementData);
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
