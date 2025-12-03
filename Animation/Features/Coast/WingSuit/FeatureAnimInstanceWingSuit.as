
UCLASS(Abstract)
class UFeatureAnimInstanceWingSuit : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureWingSuit Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	
	
	FHazeAcceleratedFloat UpperBodyRollSpring;

	FHazeAcceleratedFloat UpperBodyPitchSpring;

	FHazeAcceleratedFloat LowerBodyRollSpring;

	FHazeAcceleratedFloat LowerBodyPitchSpring;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D LowerBodyAdditiveValues;
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Additive")
	FVector2D UpperBodyAdditiveValues;
	
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWingSuitAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWingSuitBarrelRollAnimData BarrelRollAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWingSuitCrashDiveAnimData CrashDiveAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWingSuitGrappleAnimData GrappleAnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureWingSuitEnterAnimData EnterAnimData;

	// The current roll angle
    UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float SteerValue;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int BarrelRollDirection;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrapplingToPoint; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGrapplingToTrain; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bCloseToWaterSurface;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWingsuitMovementActive;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWingsuitIsLandingOnGround;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFlyingOffRamp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayBarellRoll;

	bool bIsRequestingBarellRoll;

	UPlayerMovementComponent MoveComponent;
	UWingSuitPlayerComponent WingSuitComp;

	AWingSuit WingSuit;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (Player == nullptr)
			return;

		
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureWingSuit NewFeature = GetFeatureAsClass(ULocomotionFeatureWingSuit);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
			BarrelRollAnimData = NewFeature.BarrelRollAnimData;
			CrashDiveAnimData = NewFeature.CrashDiveAnimData;
			GrappleAnimData = NewFeature.GrappleAnimData;
			EnterAnimData = NewFeature.EnterAnimData;
		}

		if (Feature == nullptr)
			return;

		WingSuit = Cast<AWingSuit>(HazeOwningActor);
		if(WingSuit == nullptr)
			WingSuit = GetWingSuitFromPlayer(HazeOwningActor);

		MoveComponent =  UPlayerMovementComponent::Get(WingSuit.PlayerOwner);
		WingSuitComp = UWingSuitPlayerComponent::Get(WingSuit.PlayerOwner);
	}

	/*UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.2;
	}
	*/

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator RootRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;	

		bGrapplingToPoint = WingSuitComp.AnimData.bIsGrappling;  
		bGrapplingToTrain = WingSuitComp.AnimData.bIsTransitioningToWaterski;
		bCloseToWaterSurface = WingSuitComp.AnimData.bCloseToWaterSurface;
		bWingsuitMovementActive = WingSuitComp.bWingsuitActive;
		bWingsuitIsLandingOnGround = WingSuitComp.AnimData.bIsLandingOnGround;

		// OLIVERL COMMENTING THE BELOW OUT SINCE MY TEST OVERRIDES THESE VALUES
		// const FVector MovementInputActorSpace = MoveComponent.SyncedMovementInputForAnimationOnly;

		// float TargetY = -Math::Clamp((WingSuitComp.InternalRotation.Pitch / 45) + MovementInputActorSpace.Z, -1.0, 1.0);
		
		// OLIVERL ADDITIONAL CODE: Per wanted the animation to change depending on which wingsuit settings he set, so that will take care of that.
		float Pitch = Math::UnwindDegrees(WingSuitComp.SyncedInternalRotation.Value.Pitch);
		float TargetY = -Pitch / 45.0;
		FVector MovementInputActorSpace = MoveComponent.SyncedMovementInputForAnimationOnly;
		float CurrentYawSpeedValue = WingSuitComp.AnimData.YawTurnSpeedDegrees / 50.0;
		// OLIVERL END ADDITIONAL CODE
		
		float BlendspaceInterpSpeedY = BlendspaceValues.Y < TargetY ? 16 : 8; 

		if(!WingSuitComp.AnimData.bIsFlyingOffRamp)
			BlendspaceValues.Y = Math::FInterpTo(BlendspaceValues.Y, TargetY, DeltaTime, BlendspaceInterpSpeedY);	
		
		if (LowestLevelGraphRelevantStateName != n"BarelRoll")
		{
			if(WingSuitComp.AnimData.bIsFlyingOffRamp)
				BlendspaceValues.Y = Math::FInterpTo(BlendspaceValues.Y, MovementInputActorSpace.X, DeltaTime, 1.5);

			BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, WingSuitComp.AnimData.bIsFlyingOffRamp ? MovementInputActorSpace.Y : CurrentYawSpeedValue, DeltaTime, 1.5);			
		}
		else 
		{
			BlendspaceValues.X = Math::FInterpTo(BlendspaceValues.X, 0, DeltaTime, 5);	
			// lendspaceValues.X = BarrelRollDirection;
		}		

		UpperBodyRollSpring.SpringTo(CurrentYawSpeedValue, 20, 0.9, DeltaTime);
		UpperBodyAdditiveValues.X = BlendspaceValues.X; 
		LowerBodyRollSpring.SpringTo(CurrentYawSpeedValue, 10, 0.7, DeltaTime);
		LowerBodyAdditiveValues.X = LowerBodyRollSpring.Value; 
		UpperBodyAdditiveValues.Y = BlendspaceValues.Y;
		LowerBodyPitchSpring.SpringTo(BlendspaceValues.Y, 400, 0.5, DeltaTime);
		LowerBodyAdditiveValues.Y = LowerBodyPitchSpring.Value;

		bIsFlyingOffRamp = WingSuitComp.AnimData.bIsFlyingOffRamp;



		bPlayBarellRoll = CheckValueChangedAndSetBool(bIsRequestingBarellRoll, WingSuitComp.AnimData.ActiveBarrelRollDirection != 0, EHazeCheckBooleanChangedDirection::FalseToTrue);
		
		if (bPlayBarellRoll)
			BarrelRollDirection = WingSuitComp.AnimData.ActiveBarrelRollDirection; 

		//LowerBodyAdditiveValues
		//LowerBodyRollSpring.SpringTo(MovementInputActorSpace
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{

		// Implement Custom Stuff Here

		return true; 
	
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
