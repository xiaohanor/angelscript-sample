UCLASS(Abstract)
class UFeatureAnimInstanceAcidTeenSpeedRing : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureAcidTeenSpeedRing Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureAcidTeenSpeedRingAnimData AnimData;

	// Add Custom Variables Here

	UHazeMovementComponent MoveComp;
	UPlayerAcidTeenDragonComponent DragonComp;
	UTeenDragonAirGlideComponent AirGlideComp; 
	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Banking;

	FQuat CachedActorRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayRight;


	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		// Get components here...

	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureAcidTeenSpeedRing NewFeature = GetFeatureAsClass(ULocomotionFeatureAcidTeenSpeedRing);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		auto TeenDragon = Cast<ATeenDragon>(HazeOwningActor);
		DragonComp = Cast<UPlayerAcidTeenDragonComponent>(TeenDragon.DragonComponent);
		MoveComp = UHazeMovementComponent::Get(DragonComp.Owner);
		AirGlideComp = UTeenDragonAirGlideComponent::Get(DragonComp.Owner);

		CachedActorRotation = HazeOwningActor.ActorQuat;
		float SideSpeed = HazeOwningActor.ActorRotation.UnrotateVector(MoveComp.Velocity).Y;
		if (Math::Abs(SideSpeed) > 10)
			bPlayRight = SideSpeed < 0;
		else
		{
			bPlayRight = Math::RandBool();
		}
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return 0.1;
	}
	

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime,230);
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag != n"AirMovement" && LocomotionAnimationTag != n"AcidTeenHover")
		{
			return true;
		}

		// if ((LocomotionAnimationTag == n"AcidTeenHover" || LocomotionAnimationTag == n"AirMovement") && TopLevelGraphRelevantAnimTimeRemainingFraction <= 0.5)
		// {	
		// 	return true;
		// }
		
		return TopLevelGraphRelevantAnimTimeRemaining <=1.1;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		// Implement Custom Stuff Here

		if (LocomotionAnimationTag == n"AcidTeenHover")
			SetAnimBoolParam(n"SkipHoverEnter",true);

		if (LocomotionAnimationTag == n"AirMovement")
			// Set a custom blend time when we blend out to movement
			SetAnimFloatParam(n"AirMovementBlendTime",0.7);   
	}
}
