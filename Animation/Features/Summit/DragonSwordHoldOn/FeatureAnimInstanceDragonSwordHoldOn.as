UCLASS(Abstract)
class UFeatureAnimInstanceDragonSwordHoldOn : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDragonSwordHoldOn Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDragonSwordHoldOnAnimData AnimData;
	UPlayerMovementComponent MoveComp;
	UPROPERTY(BlueprintReadOnly)
	UHazePhysicalAnimationProfile PhysicalAnimationProfile; 

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitToStand;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExitToMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UHazePhysicalAnimationComponent PhysComp;
	UDragonSwordPinToGroundComponent PinComp;

	// Speed
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		MoveComp = UPlayerMovementComponent::Get(Player);

		PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);

		PinComp = UDragonSwordPinToGroundComponent::Get(Player);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDragonSwordHoldOn NewFeature = GetFeatureAsClass(ULocomotionFeatureDragonSwordHoldOn);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
		
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2f;
	}
	*/

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr || MoveComp == nullptr)
			return;

		// Implement Custom Stuff Here

			Speed = MoveComp.Velocity.Size();
		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}

		bExitToStand = PinComp.ExitState == EDragonSwordPinToGroundExitAnimState::Standing;
		bExitToMoving = PinComp.ExitState == EDragonSwordPinToGroundExitAnimState::Moving;
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		
		if (LocomotionAnimationTag != n"Movement")
			return true;

		if (Player.ActorVelocity.Size() > 100)
			return true;


		return (TopLevelGraphRelevantStateName == n"Exit" || TopLevelGraphRelevantStateName == "ExitToLoco")  && IsLowestLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
		PhysComp.ClearProfileAsset(this);
	}
    UFUNCTION()
    void AnimNotify_EnterMh()
    {
        PhysComp.ApplyProfileAsset(this, PhysicalAnimationProfile);
    }

    UFUNCTION()
    void AnimNotify_LeftMh()
    {
        PhysComp.ClearProfileAsset(this);
    }

}
