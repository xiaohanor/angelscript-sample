UCLASS(Abstract)
class UFeatureAnimInstanceSwingInteract : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSwingInteract Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSwingInteractAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float BlendspaceValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPunched;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;
	UHazePhysicalAnimationComponent PhysComp;

	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::Get(Player);
		PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSwingInteract NewFeature = GetFeatureAsClass(ULocomotionFeatureSwingInteract);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PhysComp.ApplyProfileAsset(this, PhysProfile);
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTime() const
	{
		return 0.03;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		BlendspaceValue = MoveComp.SyncedLocalSpaceMovementInputForAnimationOnly.X;

		bPunched = GetAnimTrigger(n"Punched");
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName == n"Punched")
			return LocomotionAnimationTag != n"AirMovement";

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		PhysComp.ClearProfileAsset(this);
	}
}
