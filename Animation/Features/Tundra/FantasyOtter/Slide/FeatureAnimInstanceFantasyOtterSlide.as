UCLASS(Abstract)
class UFeatureAnimInstanceFantasyOtterSlide : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureFantasyOtterSlide Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureFantasyOtterSlideAnimData AnimData;

	// Add Custom Variables Here

	ATundraPlayerOtterActor Otter;
	// Since the otter mesh is on a seperate actor that is attached to player, we must use this variable instead of just Player
	AHazePlayerCharacter ParentPlayer;

	UPlayerMovementComponent MoveComp;
	UPlayerSlideComponent SlideComp;
	UPlayerSlideJumpComponent SlideJumpComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartedJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCameFromMovement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsGrounded;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "SlopeData")
	FRotator SlopeRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "SlopeData")
	float SlopeAlphaRoot;
	
	FVector InterpolatedFloorNormal;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D FallingBlendspaceValues;

	// TODO: We could use the SlopeAlignComponent here instead
	const float WantedSlopeAlphaRoot = 0.4; // How much should we rotate the root to follow the slope ?
	//const float SlideFastThreshold = 1650; // When speed is above this value it'll transition into FastSlide 
	
	bool bRotatePitchOnly;
	float TargetSlopeRotationAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RootRotation;

	FQuat CachedActorRotation;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		// Get components here...

		Otter = Cast<ATundraPlayerOtterActor>(HazeOwningActor);
		ParentPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);

		MoveComp = UPlayerMovementComponent::Get(ParentPlayer);
		SlideComp = UPlayerSlideComponent::Get(ParentPlayer);
		SlideJumpComp = UPlayerSlideJumpComponent::GetOrCreate(ParentPlayer);

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureFantasyOtterSlide NewFeature = GetFeatureAsClass(ULocomotionFeatureFantasyOtterSlide);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		CachedActorRotation = HazeOwningActor.ActorQuat;

		bCameFromMovement = PrevLocomotionAnimationTag == n"Movement";

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

		Speed = SlideComp.Speed;

		TargetSlopeRotationAlpha = GetAnimFloatParam(n"CustomSlideRotationAlpha", true, TargetSlopeRotationAlpha);

		bIsGrounded = MoveComp.IsOnWalkableGround();

		// Rotation values used for the root
		SetSmoothSlopeRotation(DeltaTime);
		
		//SlopeAlphaRoot = Math::FInterpTo(SlopeAlphaRoot, TargetSlopeRotationAlpha, DeltaTime, 3);

		SlopeAlphaRoot = Math::FInterpTo(SlopeAlphaRoot, Feature.RootRotationTarget, DeltaTime, 3);

		// Banking
		Banking = SlideComp.TurnAngle;

		bStartedJump = SlideJumpComp.bStartedJump;

		FallingBlendspaceValues.Y = Math::FInterpTo(FallingBlendspaceValues.Y, ParentPlayer.GetActorLocalVelocity().Z / 1000, DeltaTime, 0.1);
		FallingBlendspaceValues.X = Banking;


	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}
		
		if (TopLevelGraphRelevantStateName == n"Exit" && MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector)
		{
			return true;
		}

		return TopLevelGraphRelevantAnimTimeRemaining <= HazeAnimation::ANIMATION_MIN_TIME;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here
	}

	/**
	 * Get the current slope rotation (interpolated)
	 */
	void SetSmoothSlopeRotation(float DeltaTime) 
	{
		// Interpolate the floor normal
		FVector TargetFloorNormal = MoveComp.GetGroundContact().bBlockingHit ? MoveComp.GetCurrentGroundNormal() : HazeOwningActor.AttachParentActor.ActorUpVector;
		if (bRotatePitchOnly)
			TargetFloorNormal = TargetFloorNormal.VectorPlaneProject(ParentPlayer.ActorUpVector.CrossProduct(ParentPlayer.ActorForwardVector));
		
		InterpolatedFloorNormal = Math::VInterpTo(InterpolatedFloorNormal, TargetFloorNormal, DeltaTime, 15);

		// TODO: This can 100% be done in a better way
		SlopeRotation = FRotator::MakeFromZY(
			ParentPlayer.ActorTransform.InverseTransformVector(InterpolatedFloorNormal), 
			ParentPlayer.ActorTransform.InverseTransformVector(HazeOwningActor.AttachParentActor.ActorRightVector)
			);
		SlopeRotation.Yaw = 0;

		RootRotation.Pitch = Math::FInterpTo(RootRotation.Pitch, SlopeRotation.Pitch, DeltaTime, 15);
		RootRotation.Yaw = Math::FInterpTo(RootRotation.Yaw, SlopeRotation.Yaw, DeltaTime, 15);
		RootRotation.Roll = Math::FInterpTo(RootRotation.Roll, SlopeRotation.Roll, DeltaTime, 15);

		
	}
}
