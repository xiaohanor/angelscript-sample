UCLASS(Abstract)
class UFeatureAnimInstanceDecimatorPush : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureDecimatorPush Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureDecimatorPushAnimData AnimData;

	UHazeMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		const auto DragonOwner = Cast<ATeenDragon>(HazeOwningActor);
		const auto RidingPlayer = Cast<AHazePlayerCharacter>(DragonOwner.DragonComponent.Owner);

		MoveComp = UHazeMovementComponent::Get(RidingPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureDecimatorPush NewFeature = GetFeatureAsClass(ULocomotionFeatureDecimatorPush);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr || MoveComp == nullptr)
			return;

		Speed = MoveComp.Velocity.Size();
		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
	}
}
