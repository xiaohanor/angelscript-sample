UCLASS(Abstract)
class UFeatureAnimInstanceAcidTeenHover : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAcidTeenHover Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAcidTeenHoverAnimData AnimData;

	// Add Custom Variables Here
	UHazeMovementComponent MoveComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAirGlideComponent AirGlideComp; 
	

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
 
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFlapWings = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bLoopFlapWingsAnimation = false;

	FQuat CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float HorizontalSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector2D BlendspaceValues;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bDoubleJump; 


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAcidTeenHover NewFeature = GetFeatureAsClass(ULocomotionFeatureAcidTeenHover);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
		
		auto TeenDragon = Cast<ATeenDragon>(HazeOwningActor);
	
		DragonComp = Cast<UPlayerAcidTeenDragonComponent>(TeenDragon.DragonComponent);
		MoveComp = UHazeMovementComponent::Get(DragonComp.Owner);
		AirGlideComp = UTeenDragonAirGlideComponent::Get(DragonComp.Owner);
		CachedActorRotation = HazeOwningActor.ActorQuat;	
		
		//bSkipEnter = PrevLocomotionAnimationTag == (n"AcidTeenAirCurrent");
		bSkipEnter = GetAnimBoolParam(n"SkipHoverEnter",true); 
		bDoubleJump = AirGlideComp.bActivatedWithInitialBoost; 
		
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		Speed = MoveComp.Velocity.Size();
		HorizontalSpeed = MoveComp.Velocity.Size2D();
		BlendspaceValues.Y = HorizontalSpeed / 2100;
		
		


		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}
		
		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime,230);
		
		

		bPlayExit = LocomotionAnimationTag != Feature.Tag; 

		if(DragonComp != nullptr)
		{
			bFlapWings = DragonComp.bWantToFlapWings;
			bLoopFlapWingsAnimation = DragonComp.bLoopWingFlaps;
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
		if (LocomotionAnimationTag == n"AirMovement")
			// Set a custom blend time when we blend out to movement
			SetAnimFloatParam(n"AirMovementBlendTime",0.6);
	}
}
