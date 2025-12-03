UCLASS(Abstract)
class UFeatureAnimInstanceRaftSwim : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRaftSwim Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRaftSwimAnimData AnimData;

	//Components

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
		ULocomotionFeatureRaftSwim NewFeature = GetFeatureAsClass(ULocomotionFeatureRaftSwim);
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

		bExit = LocomotionAnimationTag != n"RaftSwim";

		if(PlayerInteractionComp.ActiveInteraction == nullptr)
			return;

		auto FloatingPlatform = Cast<ASplitTraversalDraggableFloatingPlatform>(PlayerInteractionComp.ActiveInteraction.Owner);
		if(FloatingPlatform == nullptr)
			return;

		FVector PlatformVelocity = FloatingPlatform.FantasyTranslateVelocityTrackerComp.LastFrameTranslationVelocity;
		ForwardBackwardSpeed = PlatformVelocity.DotProduct(-FloatingPlatform.ActorForwardVector);
		RightLeftSpeed = PlatformVelocity.DotProduct(-FloatingPlatform.ActorRightVector);

		const float MaxSpeed = 200;
		ForwardBackwardSpeed = Math::GetMappedRangeValueClamped(FVector2D(-MaxSpeed, MaxSpeed), FVector2D(-1, 1), ForwardBackwardSpeed);
		RightLeftSpeed = Math::GetMappedRangeValueClamped(FVector2D(-MaxSpeed, MaxSpeed), FVector2D(-1, 1), RightLeftSpeed);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag != n"UnderwaterSwimming" && LocomotionAnimationTag != n"SurfaceSwimming")
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
