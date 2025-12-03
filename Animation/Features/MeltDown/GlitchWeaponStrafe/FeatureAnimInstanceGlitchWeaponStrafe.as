UCLASS(Abstract)
class UFeatureAnimInstanceGlitchWeaponStrafe : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureGlitchWeaponStrafe Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureGlitchWeaponStrafeAnimData AnimData;

	// Add Custom Variables Here

	UPlayerStrafeComponent StrafeComponent;
	UPlayerMovementComponent MovementComponent;
	UMeltdownGlitchShootingUserComponent ShootingComponent;
	UMeltdownGlitchSwordUserComponent SwordComp;
	UMeltdownGlitchBazookaUserComponent BazookaComp;
	UAnimFootTraceComponent FootTraceComp;

	UPROPERTY(BlueprintReadOnly)
	FPlayerStrafeAnimData StrafeAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	EHazeCardinalDirection MovementDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float OrientationAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float MoveSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	bool bIsStopping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStopShooting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInUnequipState;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAirborne;

	//Set to true when being put in the feature from the get weapon cutscenes in Phase 1 and Phase 3. Turns false when moving or shooting.
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCutsceneAimState;

	//Set to 1 if in Phase 1 or Phase 3 where the guns are used, 0 in Phase2 where the sword is used
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float GunAlpha;

	//Set to 1 if in Phase2 where the sword is used, 0 in Phase1 and Phase3 where the guns are used
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SwordAlpha;

	//Set to true when triggering a new sword attack
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bStartSwordAttack;

	//Direction to swing sword from. This alternates between left and right with each attack
	UPROPERTY()
	EGlitchSwordAttackType SwordAttackDirection;

	//Controlling the blendspace in degrees of rotation from current facing. 90 to -90 vertical (AimSpaceValues.Y) and -90 to 90 horizontal (AimSpaceValues.X)
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D AimSpaceValues;

	//SETTINGS
	
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
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...
		StrafeComponent = UPlayerStrafeComponent::GetOrCreate(Player);
		MovementComponent = UPlayerMovementComponent::Get(Player);
		ShootingComponent = UMeltdownGlitchShootingUserComponent::Get(Player);

		SwordComp = UMeltdownGlitchSwordUserComponent::Get(Player);
		BazookaComp = UMeltdownGlitchBazookaUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureGlitchWeaponStrafe NewFeature = GetFeatureAsClass(ULocomotionFeatureGlitchWeaponStrafe);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bInUnequipState = false;

		
		bCutsceneAimState = false;
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

		MoveSpeed = MovementComponent.Velocity.Size2D();

		bWantsToMove = !MovementComponent.GetSyncedMovementInputForAnimationOnly().IsNearlyZero();
		
		if (SwordComp != nullptr)
		{
			GunAlpha = 0.0;
			SwordAlpha = 1.0;
			bStartSwordAttack = SwordComp.LastSwordAttackFrame >= GFrameNumber-1;
			SwordAttackDirection = SwordComp.LastSwordAttackDirection;
		}
		else
		{
			GunAlpha = 1.0;
			SwordAlpha = 0.0;
		}
		
		// Check if player is stopping
		if (CheckValueChangedAndSetBool(bIsStopping, bWantsToMove, EHazeCheckBooleanChangedDirection::TrueToFalse))
		{
			StoppingSpeed = MoveSpeed;
		}

		bStopShooting = (LocomotionAnimationTag != "GlitchWeaponStrafe" && OverrideFeatureTag != "GlitchWeaponStrafe");
		AimSpaceValues = CalculateAimAngles(ShootingComponent.AimDirection, Player.ActorTransform);
		bCutsceneAimState = ShootingComponent.bCutsceneAiming;

		FVector LocalVelocity;

		LocalVelocity = Player.GetActorLocalVelocity();

		bIsAirborne = MovementComponent.IsInAir();

		// // If player is acutally moving around, update angle & direction
		if (Math::Abs(LocalVelocity.Size()) > 10 && bWantsToMove)
		{
			OrientationAngle = FRotator::MakeFromXZ(LocalVelocity, Player.ActorUpVector).Yaw;
			const auto NewMovementDirection = GetStrafeDirection(MovementDirection, OrientationAngle);
			if (MovementDirection != NewMovementDirection)
				// MovementDir was updated, run function again to check if we can take an additional step (e.g. Fwd -> Left -> Bck) 
				MovementDirection = GetStrafeDirection(NewMovementDirection, OrientationAngle);
			else
				MovementDirection = NewMovementDirection;
		}


	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag != n"Movement")
		{
			return true;
		}

		if (GunAlpha == 1 && LocomotionAnimationTag == n"Movement" && (LowestLevelGraphRelevantStateName == n"Shoot_Stop" && IsLowestLevelGraphRelevantAnimFinished()))
		{
			return true;
		}

		if (SwordAlpha == 1 && LocomotionAnimationTag == n"Movement" && LowestLevelGraphRelevantAnimTimeFraction >= 0.9)
		{
			return true;
		}

		if (SwordAlpha == 1 && LowestLevelGraphRelevantStateName == n"SwordUnequipState")
		{
			return true;
		}

		if (bInUnequipState)
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
    void AnimNotify_UnequipFinished()
    {
        bInUnequipState = true;
    }

}

enum EGlitchSwordAttackType

{
	Left,
	Right,
	

}