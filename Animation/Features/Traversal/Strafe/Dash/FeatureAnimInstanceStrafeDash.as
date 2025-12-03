UCLASS(Abstract)
class UFeatureAnimInstanceStrafeDash : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureStrafeDash Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureStrafeDashAnimData AnimData;

	UPlayerMovementComponent MoveComp;
	UPlayerStepDashComponent StepDashComponent;
	UPlayerStrafeComponent StrafeComponent;
	UPlayerRollDashComponent RollDashComponent;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EStepDashDirection StepDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D StepDashDirection2D;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D RollDashDirection2D;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SignedForwardAlignedSpeed = 0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SignedRightAlignedSpeed = 0;

	bool bInDashStrafeExitState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float OrientationAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection MovementDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bStartStepDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartRollDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LocalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

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
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureStrafeDash NewFeature = GetFeatureAsClass(ULocomotionFeatureStrafeDash);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		MoveComp = UPlayerMovementComponent::Get(Player);
		StepDashComponent = UPlayerStepDashComponent::Get(Player);
		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		RollDashComponent = UPlayerRollDashComponent::GetOrCreate(Player);

		bInDashStrafeExitState = false;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		StepDirection = StepDashComponent.StepDirection;
		StepDashDirection2D = StepDashComponent.BS_Strafe_Direction;
		RollDashDirection2D = RollDashComponent.BS_Strafe_Direction;

		bStartStepDash = GetAnimTrigger(n"StartStepDash");

		if (bStartStepDash)
		{
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
		}

		SignedForwardAlignedSpeed = MoveComp.HorizontalVelocity.DotProduct(Player.ActorForwardVector);
		SignedRightAlignedSpeed = MoveComp.HorizontalVelocity.DotProduct(Player.ActorRightVector);

		bStartRollDash = GetAnimTrigger(n"StartRollDash");

		if (bStartRollDash)
		{
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", true);
		}

		SetAnimBoolParam(n"IsInStrafeDash", true);
		//PrintToScreenScaled("MovementDirection: " + MovementDirection, 0.f, Scale = 3.f);

		//Orientation angle logic

		LocalVelocity = Player.GetActorLocalVelocity();

		// TODO: This doesn't support other world up, but works now as a test
		// LocalVelocity = FRotator(0, AdditionalRotation, 0).UnrotateVector(LocalVelocity);

		bWantsToMove = !MoveComp.GetSyncedMovementInputForAnimationOnly().IsNearlyZero();

		// Speed = LocalVelocity.Size();

		// // If player is acutally moving around, update angle & direction
		if (Math::Abs(LocalVelocity.Size()) > 10)
		{
			OrientationAngle = FRotator::MakeFromXZ(LocalVelocity, Player.ActorUpVector).Yaw;
			const auto NewMovementDirection = GetStrafeDirection(MovementDirection, OrientationAngle);
			if (MovementDirection != NewMovementDirection)
				// MovementDir was updated, run function again to check if we can take an additional step (e.g. Fwd -> Left -> Bck) 
				MovementDirection = GetStrafeDirection(NewMovementDirection, OrientationAngle);
			else
				MovementDirection = NewMovementDirection;
		}

		// else if (!bWantsToMove) { //  && !StrafeAnimData.bKeepOrientationInMh for now let's always go back to 0
		// 	float Target = 0;
		// 	if (MovementDirection == EHazeCardinalDirection::Backward)
		// 		Target = 180 * Math::Clamp(OrientationAngle, -1, 1);
		// 	else if (MovementDirection != EHazeCardinalDirection::Forward)
		// 		Target = 90 * Math::Clamp(OrientationAngle, -1, 1);
		// 	OrientationAngle = Math::FInterpTo(OrientationAngle, Target, DeltaTime, 6);
		// }

			
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.05;
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
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"StrafeFloor")
		{
			return true;
		}

		// if (LowestLevelGraphRelevantStateName == n"ExitToMovement" && IsLowestLevelGraphRelevantAnimFinished())
		// {
		// 	return true;
		// }

		if (bInDashStrafeExitState && IsLowestLevelGraphRelevantAnimFinished() && !bStartRollDash)
		{
			return true;
		}

		// if (LowestLevelGraphRelevantStateName == n"RollDash_Exit" && IsLowestLevelGraphRelevantAnimFinished())
		// {
		// 	return true;
		// }

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
			SetAnimBoolParam(n"RequestingLocalUpperBodyOverrideAnimation", false);
			SetAnimBoolParam(n"IsInStrafeDash", false);
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

    UFUNCTION()
    void AnimNotify_StepDashStrafeExit()
    {
        bInDashStrafeExitState = true;
    }

    UFUNCTION()
    void AnimNotify_LeftStrafeStepDash()
    {
        bInDashStrafeExitState = false;
    }

 	UFUNCTION()
    void AnimNotify_RollDashStrafeExit()
    {
        bInDashStrafeExitState = true;
    }

    UFUNCTION()
    void AnimNotify_LeftStrafeRollDash()
    {
        bInDashStrafeExitState = false;
    }

  
}
