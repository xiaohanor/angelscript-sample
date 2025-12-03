UCLASS(Abstract)
class UFeatureAnimInstanceBoxPush : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureBoxPush Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureBoxPushAnimData AnimData;

	UPlayerMovementComponent MoveComp;
	UPlayerInteractionsComponent PlayerInteractionComp;

	// Add Custom Variables Here

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bExit;
	
	/**
	 * Forward: 1
	 * Backward: -1
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ForwardBackwardSpeed = 0;

	/**
	 * Right: 1
	 * Left: -1
	 */
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RightLeftSpeed = 0;

	//Becomes true when player starts giving input, false when no longer giving input
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	//The value/movement direction before player stopped giving movement input
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float ForwardBackwardStoppingSpeed;

	//The value/movement direction before player stopped giving movement input
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RightLeftStoppingSpeed;



	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

		MoveComp = UPlayerMovementComponent::GetOrCreate(Player);
		PlayerInteractionComp = UPlayerInteractionsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureBoxPush NewFeature = GetFeatureAsClass(ULocomotionFeatureBoxPush);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bExit = false;
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
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bExit = LocomotionAnimationTag != n"BoxPush";

		if(PlayerInteractionComp.ActiveInteraction == nullptr)
			return;

		auto PushableMushroom = Cast<ASplitTraversalPushableMushroom>(PlayerInteractionComp.ActiveInteraction.Owner);
		if(PushableMushroom == nullptr)
			return;

		ForwardBackwardSpeed = PushableMushroom.ActorVelocity.DotProduct(PushableMushroom.ActorForwardVector);
		RightLeftSpeed = PushableMushroom.ActorVelocity.DotProduct(PushableMushroom.ActorRightVector);

		const float MaxSpeed = 200;
		ForwardBackwardSpeed = Math::GetMappedRangeValueClamped(FVector2D(-MaxSpeed, MaxSpeed), FVector2D(-1, 1), ForwardBackwardSpeed);
		RightLeftSpeed = Math::GetMappedRangeValueClamped(FVector2D(-MaxSpeed, MaxSpeed), FVector2D(-1, 1), RightLeftSpeed);

		bWantsToMove = PushableMushroom.bIsMoving;

		ForwardBackwardStoppingSpeed = PushableMushroom.VelocityOnStoppedMoving.DotProduct(PushableMushroom.ActorForwardVector);
		RightLeftStoppingSpeed = PushableMushroom.VelocityOnStoppedMoving.DotProduct(PushableMushroom.ActorRightVector);

		ForwardBackwardStoppingSpeed = Math::GetMappedRangeValueClamped(FVector2D(-MaxSpeed, MaxSpeed), FVector2D(-1, 1), ForwardBackwardStoppingSpeed);
		RightLeftStoppingSpeed = Math::GetMappedRangeValueClamped(FVector2D(-MaxSpeed, MaxSpeed), FVector2D(-1, 1), RightLeftStoppingSpeed);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}

		if (IsLowestLevelGraphRelevantAnimFinished() || (LowestLevelGraphRelevantAnimTimeFraction >= 0.25 && MoveComp.Velocity.Size() >= 50))
		{
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}
}
