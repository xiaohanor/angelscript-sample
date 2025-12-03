enum ESpaceHookHand
{
	HookLeftHand,
	HookRightHand
}

UCLASS(Abstract)
class UFeatureAnimInstanceZeroG : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureZeroG Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureZeroGAnimData AnimData;

	// Add Custom Variables Here

	UPlayerMovementComponent MoveComp;
	USpaceWalkPlayerComponent SpaceComp;
	
	// Physical Animation
	UHazePhysicalAnimationComponent PhysAnimComp;

	// Current horizontal speed of the player
	UPROPERTY()
	float MovementSpeed;

	UPROPERTY()
	float Turnspeed;

	// Distance to the hook point we're currently trying to attach to
	UPROPERTY()
	FVector DistanceToTarget;

	// Position of the hook point we want to attach to
	UPROPERTY()
	FVector TargetWorldPosition;

	// Current position of the actual hook (will be different to the target position when it is shooting out)
	UPROPERTY()
	FVector HookWorldPosition;

	// Whether the hook is currently launched from the player. If false, player is not firing or attached
	UPROPERTY()
	bool bHasHookLaunched;

	// Whether the hook is currently attached to something. Will become true after the hook hits the target point
	UPROPERTY()
	bool bHasHookAttached;

	// Whether the hook is currently returning back to the player after detaching
	UPROPERTY()
	bool bIsHookReturning;

	// Whether the previous time we released the hook it was forced (by moving past the target point) instead of the player releasing the button
	UPROPERTY()
	bool bHookForceRelease;

	// The yaw (relative to the player) that we launched the hook from when we first launched it
	UPROPERTY()
	float HookLaunchYaw;

	UPROPERTY()
	float LeftArmAlpha;

	UPROPERTY()
	float RightArmAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float HipsAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Diff;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator AngleToPoint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ESpaceHookHand HookingHand;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float ArmAimValueX;

	bool bCalculateLeftArmAlpha;

	bool bCalculateRightArmAlpha;

	bool bSavePitchAngle;

	FRotator SavedAngleToPoint;

	//The angle towards the target location, lerps between AngleToPoint and SavedAngleToPoint depending on if you are currently hooking towards a point or not
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator HipsRotation;

	




	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		// Get components here...
		MoveComp = UPlayerMovementComponent::Get(Player);
		SpaceComp = USpaceWalkPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureZeroG NewFeature = GetFeatureAsClass(ULocomotionFeatureZeroG);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
		
		HipsAlpha = 0;

		LeftArmAlpha = 0;

		RightArmAlpha = 0;

		HipsRotation.Pitch = 0;

		bCalculateLeftArmAlpha = false;

		bCalculateRightArmAlpha = false;
		

		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);

		PhysAnimComp.ApplyProfileAsset(this, Feature.PhysAnimProfile, BlendTime = 0.2);

		

	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		if (PrevLocomotionAnimationTag == n"SpaceTouchScreen")
		{
			return 1;
		}

		else 

		return 0.2;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
		MovementSpeed = MoveComp.HorizontalVelocity.Size2D();

		HipsAlpha = Math::FInterpTo(HipsAlpha, 1, DeltaTime, 1);

		if (SpaceComp.TargetHookPoint != nullptr)
			TargetWorldPosition = SpaceComp.TargetHookPoint.WorldLocation;

		if (SpaceComp.Hook != nullptr)
			HookWorldPosition = SpaceComp.Hook.ActorLocation;

		DistanceToTarget = TargetWorldPosition - HazeOwningActor.ActorLocation;
								
		//FVector FlattenedDirection = DistanceToTarget.ConstrainToPlane(MoveComp.WorldUp);
		// float AngleDiff = Math::Acos(FlattenedDirection.GetSafeNormal().DotProduct(OwningActor.ActorForwardVector));
		//HookLaunchYaw = Math::Atan2(FlattenedDirection.DotProduct(HazeOwningActor.ActorRightVector), FlattenedDirection.DotProduct(HazeOwningActor.ActorForwardVector));
		//HookLaunchYaw = Math::RadiansToDegrees(HookLaunchYaw);

		FVector UnRotated = HazeOwningActor.ActorRotation.UnrotateVector(DistanceToTarget);
		AngleToPoint = FRotator::MakeFromXY(UnRotated, FVector::RightVector);

		bHasHookLaunched = SpaceComp.bHasHookLaunched;
		bHasHookAttached = SpaceComp.bHasHookAttached;
		bIsHookReturning = SpaceComp.bIsHookReturning;
		bHookForceRelease = SpaceComp.bHookForceRelease;
		HookLaunchYaw = SpaceComp.HookLaunchYaw;

		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly != FVector::ZeroVector;

		Turnspeed = Math::FInterpTo(Turnspeed, MoveComp.GetMovementYawVelocity(false)/180, DeltaTime, 3);

		ArmAimValueX = AngleToPoint.Yaw / 180;


		//Decide which hand to launch with
		if (HookLaunchYaw < -15)
			{
				HookingHand = ESpaceHookHand::HookLeftHand;
				bCalculateRightArmAlpha = false;
			}
		else
			{
				HookingHand = ESpaceHookHand::HookRightHand;
				bCalculateLeftArmAlpha = false;
			}
		
		
		if (bHasHookAttached && HookingHand == ESpaceHookHand::HookLeftHand)// && bCalculateLeftArmAlpha)
			{
				LeftArmAlpha = Math::FInterpTo(LeftArmAlpha, 1, DeltaTime,3);
			}
		else
			{
				LeftArmAlpha = Math::FInterpTo(LeftArmAlpha, 0, DeltaTime, 4);
			}

		if (bHasHookAttached && HookingHand == ESpaceHookHand::HookRightHand)// && bCalculateRightArmAlpha)
			{
				RightArmAlpha = Math::FInterpTo(RightArmAlpha, 1, DeltaTime, 3);
			}
		else
			{
				RightArmAlpha = Math::FInterpTo(RightArmAlpha, 0, DeltaTime, 4);
			}

		

		if (CheckValueChangedAndSetBool(bSavePitchAngle, ((DistanceToTarget.Size() < 1000) || bIsHookReturning), EHazeCheckBooleanChangedDirection::FalseToTrue))
			{
				SavedAngleToPoint = AngleToPoint;
			}
		
		SavedAngleToPoint.Pitch = Math::FInterpTo(SavedAngleToPoint.Pitch, 0, DeltaTime, 1);

		if (bHasHookAttached)
			{
				HipsRotation.Pitch = Math::FInterpTo(HipsRotation.Pitch, AngleToPoint.Pitch, DeltaTime, 10);
			}
		else
			{
				HipsRotation.Pitch = SavedAngleToPoint.Pitch;
			}

		
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
		PhysAnimComp.ClearProfileAsset(this);

		HipsRotation.Pitch = 0;
	}

	UFUNCTION()
    void AnimNotify_BeginCalculatingRightArmAlpha()
    {
        bCalculateRightArmAlpha = true;
    }

	UFUNCTION()
    void AnimNotify_BeginCalculatingLeftArmAlpha()
    {
        bCalculateLeftArmAlpha = true;
    }
}
