
UCLASS(Abstract)
class UFeatureAnimInstanceSanctuaryDoppelgangerMovement : UFeatureAnimInstanceAIBase
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureMovementAnimData AnimData;

	UPlayerFloorMotionComponent 		FloorMotionComponent;
	UBasicAICharacterMovementComponent 	MovementComponent;
	UPlayerFloorSlowdownComponent 		SlowDownComponent;
	UPlayerSprintComponent 				SprintComponent;
	USanctuaryDoppelgangerComponent		DoppelComp;
	UBasicAIDestinationComponent		DestinationComp;
	UPlayerMovementComponent			MimicMoveComp;
	UAnimFootTraceComponent 			FootTraceComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FHazeSlopeWarpingData IKData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")	
	float SlopeAngle;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableSlopeWarp;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")	
	float AdditiveBanking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")	
	float AdditiveBankAlpha;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float BankingMultiplier;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	FRotator InitialRootRotationDelta;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	FRotator CurrentRootRotationDelta;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	bool bInitializeTurn;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Turns")
	bool bTurnLeft;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bStartedToSprint;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Sprint")
	bool bPlaySprintStop;

	bool bIsSprinting;


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsStopping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bTurn180;

	//Temp Bool for bypassing sprint enter in forced walk areas.
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsInForcedWalk;

	UPROPERTY(Transient)
	float RelaxTimer;

	UPROPERTY(Transient)
	bool bIsRelaxing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnableRootRotation;

	// TODO: This could be removed by updating the animations to be 'less'. Enabled for now to easily be able to tweak it
	const float MAX_ADDITIVE_BANKING = 0.35;

	// TODO: Currently used for 180 turn experiments
	FRotator CachedActorRotation;
	FRotator CapsuleRotationWhenStartedTurning;


	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		
		ULocomotionFeatureMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}
		if (Feature == nullptr)
			return;

		FloorMotionComponent = UPlayerFloorMotionComponent::Get(HazeOwningActor);
		SlowDownComponent = UPlayerFloorSlowdownComponent::Get(HazeOwningActor);
		MovementComponent =  UBasicAICharacterMovementComponent::Get(HazeOwningActor);
		SprintComponent = UPlayerSprintComponent::Get(HazeOwningActor);
		FootTraceComp = UAnimFootTraceComponent::GetOrCreate(HazeOwningActor);
		
		DoppelComp = USanctuaryDoppelgangerComponent::Get(HazeOwningActor);
		DestinationComp = UBasicAIDestinationComponent::Get(HazeOwningActor);
		MimicMoveComp = UPlayerMovementComponent::Get(DoppelComp.MimicTarget);

		bSkipStart = (MovementComponent.Velocity.Size() >= 25.0);
		
		RelaxTimer = 0;
		
		// Banking (TODO: player dependent, so ignore for now)
		BankingMultiplier = 0;
	}


	UFUNCTION(BlueprintOverride)
    float GetBlendTime() const
    {
        return GetAnimFloatParam(n"MovementBlendTime", true, 0.2);
    }

	UFUNCTION(BlueprintOverride)
    float GetBlendTimeWhenResetting() const
    {
        return 0.0;
    }

	bool WantsToMove() const
	{
		if (IsStopping())
			return false;
		return true;
	}

	bool IsStopping() const
	{
		if (!DestinationComp.HasDestination())
			return true;

		return false;
	}

	bool IsSprinting() const
	{
		return SprintComponent.IsSprinting();
	}

	float GetUpdatedAnimBankingValue(float DeltaTime)
	{
		return 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		Super::BlueprintUpdateAnimation(DeltaTime);

		if (Feature == nullptr)
			return;
			
		const bool bStartedToMove = CheckValueChangedAndSetBool(bWantsToMove, WantsToMove(), EHazeCheckBooleanChangedDirection::FalseToTrue);
		bStartedToSprint = CheckValueChangedAndSetBool(bIsSprinting, IsSprinting(), EHazeCheckBooleanChangedDirection::FalseToTrue);

		Velocity = MovementComponent.Velocity;
		Speed = Velocity.Size();

		bIsInForcedWalk = SprintComponent.IsForcedToWalk();
		
		// Banking
		// Additive Banking
		float NewAdditiveBankValue = 0;
		const float NewBankingValue = GetUpdatedAnimBankingValue(DeltaTime); 
		if (Math::Abs(Banking) < Math::Abs(NewBankingValue))
			NewAdditiveBankValue = (NewBankingValue - Banking) * 10;
		AdditiveBanking = Math::FInterpTo(AdditiveBanking, NewAdditiveBankValue, DeltaTime, 7);
		AdditiveBankAlpha = Math::Clamp(Speed / 500 * MAX_ADDITIVE_BANKING, 0.0, MAX_ADDITIVE_BANKING); 

		Banking = NewBankingValue;
		// If we just blended into this ABP, slowly blend BankingMultiplier back up to 1
		if (!Math::IsNearlyEqual(BankingMultiplier, 1))
		{
			BankingMultiplier = Math::FInterpTo(BankingMultiplier, 1.0, DeltaTime, 2.0);
			AdditiveBankAlpha *= BankingMultiplier;
		}

		// Check if character is stopping
		if (CheckValueChangedAndSetBool(bIsStopping, IsStopping(), EHazeCheckBooleanChangedDirection::FalseToTrue))
		{
			StoppingSpeed = Speed;
			
			// The ammount we're between the Run -> Sprint state, 0 = Run, 1 = Sprint 
			const float StoppingSprintRatio = (StoppingSpeed - FloorMotionComponent.Settings.MaximumSpeed) / (SprintComponent.Settings.MaximumSpeed - FloorMotionComponent.Settings.MaximumSpeed);
			bPlaySprintStop = (StoppingSprintRatio > 0.5);
				
			//FootTraceComp.GetIdleFeetPredictionData(IdleIKPredictionData, AnimData.Mh.Sequence);
		}

		// IK Data
		FootTraceComp.UpdateSlopeWarpData(IKData);
		SlopeAngle = MovementComponent.GetSlopeRotationForAnimation().Pitch;
		bEnableSlopeWarp = bWantsToMove;

		// if (!bEnableSlopeWarp)
		// 	IdleIKData = FootTraceComp.GetIdleFeetPlacementData();

		// 180 starts		
		bInitializeTurn = bStartedToMove;
		if (bStartedToMove)
		{
			CapsuleRotationWhenStartedTurning = CachedActorRotation;
			InitialRootRotationDelta = (CachedActorRotation - HazeOwningActor.ActorRotation).Normalized;
			bTurnLeft = InitialRootRotationDelta.Yaw > 0;
		}
		CurrentRootRotationDelta = (CapsuleRotationWhenStartedTurning - HazeOwningActor.ActorRotation).Normalized;
		CachedActorRotation = HazeOwningActor.ActorRotation;

		bTurn180 = GetAnimTrigger(n"Turn180");
		if (bTurn180)
		{
			bSkipStart = true;
		}
	}

    UFUNCTION()
    void AnimNotify_DecelerateToStop()
    {
        bSkipStart = false;
    }

    UFUNCTION()
    void AnimNotify_EnteredMh()
    {
		bSkipStart = false;
    }

}
