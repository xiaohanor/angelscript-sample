UCLASS(Abstract)
class UFeatureAnimInstanceSnowball : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSnowball Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSnowballAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bThrow;

	UPROPERTY(EditDefaultsOnly)
	UHazePhysicalAnimationProfile PhysProfile;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UHazePhysicalAnimationComponent PhysAnimComp;
	UPlayerMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSnowball NewFeature = GetFeatureAsClass(ULocomotionFeatureSnowball);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bThrow = GetAnimTrigger(n"ThrowSnowball");
		if (bThrow)
		{
			PhysAnimComp.SetBoneSimulated(n"RightArm", false, BlendTime = 0);
			PhysAnimComp.ClearProfileAsset(this, 0.06);
		}

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero() && MoveComp.IsOnAnyGround();
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (TopLevelGraphRelevantStateName != n"Throw")
			return !GetAnimBoolParam(n"ThrowSnowball", false);

		return IsTopLevelGraphRelevantAnimFinished();
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		PhysAnimComp.ClearProfileAsset(this);
	}

	UFUNCTION()
	void AnimNotify_EnteredMh()
	{
		PhysAnimComp.ApplyProfileAsset(this, PhysProfile);
	}

	UFUNCTION(BlueprintOverride)
	float32 GetBlendTimeToNullFeature() const
	{
		if (MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero())
			return 0.5;

		return 0.3;
	}
}
