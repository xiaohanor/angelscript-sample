UCLASS(Abstract)
class UFeatureAnimInstanceTailTeenRoll : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureTailTeenRoll Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureTailTeenRollAnimData AnimData;

	UHazePhysicalAnimationComponent PhysicalAnimComp;
	UHazeMovementComponent MoveComp;

	
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayExit;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bJump;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float RollLoopPlaySpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bHitObjectWhileRoll; 

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsAboutToLandFromAirRoll;

	bool bHasEnabledPhysics;

	

	FQuat CachedActorRotation;
	UPlayerTeenDragonComponent DragonComp;

	UTeenDragonRollSettings RollSettings;

	AHazePlayerCharacter PlayerRef;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;
		PlayerRef = Player;  
		if (PlayerRef == nullptr)
		{
			PlayerRef = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
			PhysicalAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
		}
		
		MoveComp = UHazeMovementComponent::Get(PlayerRef);
		DragonComp = UPlayerTeenDragonComponent::Get(PlayerRef);
		RollSettings = UTeenDragonRollSettings::GetSettings(PlayerRef);
	}


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureTailTeenRoll NewFeature = GetFeatureAsClass(ULocomotionFeatureTailTeenRoll);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		CachedActorRotation = HazeOwningActor.ActorQuat;
		
		// Blend out tail physics, Only for the dragons
		if (Player == nullptr)
		{
			PhysicalAnimComp.Disable(this, BlendTime = 0.5);
			bHasEnabledPhysics = false;
		}

			
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

		bPlayExit = Feature.Tag != GetLocomotionAnimationTag();
		bJump = DragonComp.bIsRollJumping; 
		bHitObjectWhileRoll = DragonComp.bWillHitObjectWhileRollJumping;
		bWantsToMove = MoveComp.SyncedMovementInputForAnimationOnly.Size() > SMALL_NUMBER;
		RollLoopPlaySpeed = GetRollAnimSpeed(MoveComp.HorizontalVelocity.Size());
		bIsAboutToLandFromAirRoll = DragonComp.bIsAboutToLandFromAirRoll;
		
		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime,110);

		
		
		
	}


	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		if (LocomotionAnimationTag != n"Movement" && LocomotionAnimationTag != n"DragonRiding")
		{
			return true;
		}

		return TopLevelGraphRelevantStateName == n"Exit" && IsLowestLevelGraphRelevantAnimFinished();
	}


	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
		if (!bHasEnabledPhysics)
			AnimNotify_EnablePhysics();
	}


    UFUNCTION()
    void AnimNotify_EnablePhysics()
    {
		// Blend in the tail physics again, only for the dragon
		if (Player == nullptr)
		{
			PhysicalAnimComp.ClearDisable(this, BlendTime = 0.5);
			bHasEnabledPhysics = true;
		}
    }

	const float AnimSpeedMax = 1.0;
	float GetRollAnimSpeed(float Speed) const
	{
		float AnimSpeed = 0.0;

		const float CapsuleRadius = PlayerRef.CapsuleComponent.ScaledCapsuleRadius;
		const float RotationSpeed = Math::RadiansToDegrees(Speed / CapsuleRadius);

		// Animation speed is set to 1200 degrees per second as a base
		AnimSpeed = RotationSpeed / 1200.0;
		AnimSpeed = Math::Min(AnimSpeed, AnimSpeedMax);

		return AnimSpeed;
	}

   

}
