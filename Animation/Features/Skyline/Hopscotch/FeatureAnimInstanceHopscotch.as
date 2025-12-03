UCLASS(Abstract)
class UFeatureAnimInstanceHopscotch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureHopscotch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureHopscotchAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJumping;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UHazePhysicalAnimationComponent PhysAnimComp;

	UPlayerPerchComponent PerchComponent;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		PerchComponent = UPlayerPerchComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureHopscotch NewFeature = GetFeatureAsClass(ULocomotionFeatureHopscotch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
		
		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
		PhysAnimComp.ApplyProfileAsset(this, PhysProfile);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bJumping = PerchComponent.Data.bJumpingOff || PerchComponent.Data.bSplineJump || PerchComponent.AnimData.bInEnter || LocomotionAnimationTag == n"AirMovement";

		Speed = Player.ActorHorizontalVelocity.Size();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag == n"AirMovement")
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		PhysAnimComp.ClearProfileAsset(this);
	}
}
