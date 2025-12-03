UCLASS(Abstract)
class UFeatureAnimInstanceTeenDragonRiding : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTeenDragonRiding Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTeenDragonRidingAnimData AnimData;

	UPlayerTeenDragonComponent DragonComp;
	UPlayerAcidTeenDragonComponent AcidDragonComp;
	UHazeMovementComponent MoveComp;
	UTeenDragonAirGlideComponent AirGlideComponent;

	//ATeenDragon TeenDragon;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	UPROPERTY(BlueprintReadOnly)
	UHazePhysicalAnimationProfile PhysicalAnimationProfile; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	int RndGestureIndex;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector LocalVelocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsSprinting;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsFiringAcid;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsHovering;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDoubleJump;   

	UHazePhysicalAnimationComponent PhysComp;

	FQuat CachedActorRotation;

	//bool bIsTailDragon;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		DragonComp = UPlayerTeenDragonComponent::Get(HazeOwningActor);
		//TeenDragon = DragonComp.TeenDragon;
		
		//bIsTailDragon = TeenDragon.Player != Game::Mio;
		//if (!bIsTailDragon)
		AcidDragonComp = UPlayerAcidTeenDragonComponent::Get(HazeOwningActor);

		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);

		AirGlideComponent = UTeenDragonAirGlideComponent::Get(HazeOwningActor);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTeenDragonRiding NewFeature = GetFeatureAsClass(ULocomotionFeatureTeenDragonRiding);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CachedActorRotation = HazeOwningActor.ActorQuat;
		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true) && !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		// PhysComp = UHazePhysicalAnimationComponent::GetOrCreate(Player);
		// PhysComp.ApplyProfileAsset(this, PhysicalAnimationProfile);
		
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		
		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);
		bIsSprinting = DragonComp.bIsSprinting;
		if (AirGlideComponent != nullptr)
			bIsHovering = AirGlideComponent.bIsAirGliding; 
		LocalVelocity = Player.ActorRotation.UnrotateVector(Player.GetActorVelocity());
		Speed = MoveComp.Velocity.Size();

		
		
		
		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}

		// Gestures
		if (CheckValueChangedAndSetBool(bPlayGesture, 
										GetAnimBoolParam(n"PlayDragonGesture", true, false), 
										EHazeCheckBooleanChangedDirection::FalseToTrue)) 
		{
			RndGestureIndex = GetAnimIntParam(n"GestureNumber", true, 0);

			// Validate that the player has that index, otherwise skip playing a gesture
			if (AnimData.Gestures.GetNumAnimations() <= RndGestureIndex)
				bPlayGesture = false;
		}

		if (AcidDragonComp != nullptr)
		{
			bIsFiringAcid = AcidDragonComp.bIsFiringAcid;
			bDoubleJump = AirGlideComponent.bActivatedWithInitialBoost; 
		}

		
		
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
        // PhysComp.ClearDisable(this, 0.2);
	}

    UFUNCTION()
    void AnimNotify_EnterGestures()
    {
        // PhysComp.Disable(this, 0.2);
    }

    UFUNCTION()
    void AnimNotify_LeftGeastures()
    {
        // PhysComp.ClearDisable(this, 0.2);
    }

	UFUNCTION()
	void AnimNotify_LeftMh()
	{
		bSkipStart = false;
	}

}
