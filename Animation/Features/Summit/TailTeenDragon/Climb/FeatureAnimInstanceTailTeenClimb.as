UCLASS(Abstract)
class UFeatureAnimInstanceTailTeenClimb : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTailTeenClimb Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTailTeenClimbAnimData AnimData;

	// Add Custom Variables Here

	UHazeMovementComponent MoveComp;
	
	UTeenDragonTailGeckoClimbComponent GeckoClimbComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
 
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bInAir;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bGeckoDash;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsJumpingOntoWall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHasReachedWall;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsLedgeGrabbing = false;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	FQuat CachedActorRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{				
		const bool bIsPlayer = HazeOwningActor.IsA(AHazePlayerCharacter);
		if (bIsPlayer)
		{
			MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
			GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::GetOrCreate(HazeOwningActor);
		}
		else
		{
			ATeenDragon TeenDragon = Cast<ATeenDragon>(HazeOwningActor);
			
			auto DragonComp = Cast<UPlayerTeenDragonComponent>(TeenDragon.DragonComponent);
			MoveComp = UHazeMovementComponent::Get(DragonComp.Owner);
			GeckoClimbComp = UTeenDragonTailGeckoClimbComponent::GetOrCreate(DragonComp.Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTailTeenClimb NewFeature = GetFeatureAsClass(ULocomotionFeatureTailTeenClimb);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CachedActorRotation = HazeOwningActor.ActorQuat;
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.0;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here
		
		Velocity = HazeOwningActor.ActorRotation.UnrotateVector(MoveComp.Velocity);
		
		float NewBankingValue = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, 230);
		Banking = Math::FInterpTo(Banking, NewBankingValue, DeltaTime, 5);
		PrintToScreenScaled("Banking: " + Banking, 0.f, Scale = 3.f);
		
		
		
		bPlayExit = LocomotionAnimationTag != Feature.Tag; 

		bInAir = MoveComp.IsInAir();

		bGeckoDash = GeckoClimbComp.bIsGeckoDashing;

		bHasReachedWall = GeckoClimbComp.bHasReachedWall; 

		bIsJumpingOntoWall = GeckoClimbComp.bIsJumpingOntoWall;

		bWantsToMove = !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero();
		
		if(GeckoClimbComp != nullptr)
			bIsLedgeGrabbing = GeckoClimbComp.bIsLedgeGrabbing;
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
		// Implement Custom Stuff Here
	}
}
