UCLASS(Abstract)
class UFeatureAnimInstanceStrafe : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStrafe Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStrafeAnimData AnimData;

	UPlayerStrafeComponent StrafeComponent;
	UPlayerMovementComponent MovementComponent;
	UAnimFootTraceComponent FootTraceComp;

	UPROPERTY(BlueprintReadOnly)
	FPlayerStrafeAnimData StrafeAnimData;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FHazeSlopeWarpingData SlopeWarpData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIKFeetPlacement;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float OrientationAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection MovementDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StartAnimationFinishedBlendTime = 0.1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ExplicitStartTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FVector LocalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bWasAlreadyMoving;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCanTransition;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWarpMh;
	
	bool bCalculateExplicitTime;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator InitialFacingAngleDifference;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator FacingAngleDifference;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float AdditionalRotation;


	// SETTINGS

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Orientation Warping")
	const float OrientationWarpingBodyRotationAlpha = 0.5;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Orientation Warping")
	const float OrientationWarpingRotationInterpSpeed = 10;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	const float Threshold = 5;

	const float FwdRightAngle = 45;
	const float FwdLeftAngle = -75;
	const float BckRightAngle = 105;
	const float BckLeftAngle = -135;

	
	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStrafe NewFeature = GetFeatureAsClass(ULocomotionFeatureStrafe);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;


		InitialFacingAngleDifference = (StrafeComponent.GetDefaultFacingRotation(Player) - HazeOwningActor.GetActorRotation()).Normalized;

		bWasAlreadyMoving = (MovementComponent.Velocity.Size() >= 25.0);
		bWarpMh = false;

		FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);
	}


	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
		return GetAnimFloatParam(n"MovementBlendTime", true, 0.1);
    }


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		StrafeAnimData = StrafeComponent.AnimData;
		AdditionalRotation = StrafeComponent.StrafeYawOffset;

		LocalVelocity = Player.GetActorLocalVelocity();
		// TODO: This doesn't support other world up, but works now as a test
		LocalVelocity = FRotator(0, AdditionalRotation, 0).UnrotateVector(LocalVelocity);

		Speed = LocalVelocity.Size();

		// TODO: What was the plan here?
		FacingAngleDifference = (StrafeComponent.GetDefaultFacingRotation(Player) - HazeOwningActor.GetActorRotation()).Normalized; 

		const bool bNewHasInput = !MovementComponent.GetSyncedMovementInputForAnimationOnly().IsNearlyZero();
		if (CheckValueChangedAndSetBool(bWantsToMove, bNewHasInput))
		{
			if (bWantsToMove)
			{
				// Player just started giving input
				ExplicitStartTime = 0.0;
				bCalculateExplicitTime = true;
				bCanTransition = false;
			}
			else
			{
				// Player stopped giving input
				
			}
		}

		// If player is acutally moving around, update angle & direction
		if (Speed > 10 && bWantsToMove)
		{
			OrientationAngle = FRotator::MakeFromXZ(LocalVelocity, Player.ActorUpVector).Yaw;
			const auto NewMovementDirection = GetStrafeDirection(MovementDirection, OrientationAngle);
			if (MovementDirection != NewMovementDirection)
				// MovementDir was updated, run function again to check if we can take an additional step (e.g. Fwd -> Left -> Bck) 
				MovementDirection = GetStrafeDirection(NewMovementDirection, OrientationAngle);
			else
				MovementDirection = NewMovementDirection;
		}

		else if (!bWantsToMove) { //  && !StrafeAnimData.bKeepOrientationInMh for now let's always go back to 0
			float Target = 0;
			if (MovementDirection == EHazeCardinalDirection::Backward)
				Target = 180 * Math::Clamp(OrientationAngle, -1, 1);
			else if (MovementDirection != EHazeCardinalDirection::Forward)
				Target = 90 * Math::Clamp(OrientationAngle, -1, 1);
			OrientationAngle = Math::FInterpTo(OrientationAngle, Target, DeltaTime, 6);
		}

		if (bCalculateExplicitTime)
			ExplicitStartTime += DeltaTime;

		// IK Data
		const bool bTraceAllFeet = CheckValueChangedAndSetBool(bEnableIKFeetPlacement, FootTraceComp.AreRequirementsMet(), EHazeCheckBooleanChangedDirection::FalseToTrue);
		if (bEnableIKFeetPlacement)
			FootTraceComp.TraceFeet(IKFeetPlacementData, bTraceAllFeet);
		else
			FootTraceComp.UpdateSlopeWarpData(SlopeWarpData);
		
		// Calculate the slope rotation
		FVector NormalActorSpace = Player.ActorTransform.InverseTransformVectorNoScale(MovementComponent.CurrentGroundNormal);
		SlopeRotation = FRotator::MakeFromZX(NormalActorSpace, FVector::ForwardVector);
	}


	UFUNCTION(BlueprintPure, Meta = (BlueprintThreadSafe))
	float GetOrientationWarpingAngle(EHazeCardinalDirection Direction)
	{
		if (Direction == EHazeCardinalDirection::Forward)
			return OrientationAngle;
		else if (Direction == EHazeCardinalDirection::Left)
			return OrientationAngle + 90;
		else if (Direction == EHazeCardinalDirection::Right)
			return OrientationAngle - 90;
		return OrientationAngle + 180;
	}


	UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		if (LocomotionAnimationTag == "Movement")
			SetAnimFloatParam(n"MovementBlendTime", 0.1);
    }


    UFUNCTION()
    void AnimNotify_DecelerateToStop()
    {
		// OrientationAngleWhenStopping = OrientationAngle;
        bWasAlreadyMoving = false;
		bCanTransition = false;
		bWarpMh = true;
    }

	
    UFUNCTION()
    void AnimNotify_ResetExplicitFrame()
    {
        bCalculateExplicitTime = false;
		ExplicitStartTime = 0;
    }


	UFUNCTION()
    void AnimNotify_StartExplicitFrame()
    {
        bCalculateExplicitTime = true;

		bCanTransition = false;
    }


	UFUNCTION()
	void AnimNotify_StrafeStartCanTransition()
	{
		bCanTransition = true;
	}


	UFUNCTION()
	void AnimNotify_IsInStrafeMovement()
	{
		bCanTransition = false;
	}

	
    UFUNCTION()
    void AnimNotify_DisableMhWarping()
    {
        bWarpMh = false;
    }

	UFUNCTION()
    void AnimNotify_EnableMhWarping()
    {
        bWarpMh = true;
    }



	EHazeCardinalDirection GetStrafeDirection(EHazeCardinalDirection CurrentDirection, float Angle)
	{
		if (CurrentDirection == EHazeCardinalDirection::Forward)
		{
			if (Angle > FwdRightAngle + Threshold)
				return EHazeCardinalDirection::Right;
			else if (Angle < FwdLeftAngle - Threshold)
				return EHazeCardinalDirection::Left;
		}
		else if (CurrentDirection == EHazeCardinalDirection::Backward)
		{
			if (Angle > 0 && Angle < BckRightAngle - Threshold)
				return EHazeCardinalDirection::Right;
			else if (Angle < 0 && Angle > BckLeftAngle + Threshold)
				return EHazeCardinalDirection::Left;
		}
		else if (CurrentDirection == EHazeCardinalDirection::Right)
		{
			if (Angle > BckRightAngle + Threshold)
				return EHazeCardinalDirection::Backward;
			else if (Angle < FwdRightAngle - Threshold)
				return EHazeCardinalDirection::Forward;
		}
		else if (CurrentDirection == EHazeCardinalDirection::Left)
		{
			if (Angle < BckLeftAngle - Threshold)
				return EHazeCardinalDirection::Backward;
			else if (Angle > FwdLeftAngle + Threshold)
				return EHazeCardinalDirection::Forward;
		}

		return CurrentDirection;
	}



}
