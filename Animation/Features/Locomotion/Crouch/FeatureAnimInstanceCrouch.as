UCLASS(Abstract)
class UFeatureAnimInstanceCrouch : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureCrouch Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureCrouchAnimData AnimData;

	// Add Custom Variables Here
	UPlayerCrouchComponent CrouchComp;
	UPlayerMovementComponent MoveComponent;
	UPlayerFloorSlowdownComponent SlowdownComponent;
	UPlayerSprintComponent SprintComponent;
	UAnimFootTraceComponent	FootTraceComp;
	UHazeAnimPlayerBankingComponent BankingComp;
	
	


	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FPlayerCrouchAnimData CrouchAnimData;


	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FHazeSlopeWarpingData IKData;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "IK Data")	
	FHazeAnimIKFeetPlacementTraceDataInput IKFeetPlacementData;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "IK Data")
	bool bEnableIKFeetPlacement;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "IK Data")
	float IKAlpha = 1;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY()
	bool bIsStopping;
	
	UPROPERTY()
	bool bIsSprinting;

	UPROPERTY()
	FVector Velocity;

	UPROPERTY()
	float Speed;

	UPROPERTY(BlueprintReadOnly, Category = "Banking")
	UHazeAnimBankingDataAsset BankingAsset;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float AdditiveBanking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable, Category = "Banking")
	float AdditiveBankAlpha;

	float BankingMultiplier;

	

	// TODO: Remove this variable once the actual capsule rotation is fixed
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator TEMPRootRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureCrouch NewFeature = GetFeatureAsClass(ULocomotionFeatureCrouch);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		MoveComponent = UPlayerMovementComponent::Get(Player);

		SlowdownComponent = UPlayerFloorSlowdownComponent::GetOrCreate(Player);

		CrouchComp = UPlayerCrouchComponent::GetOrCreate(Player);
		FootTraceComp = UAnimFootTraceComponent::Get(Player);
		SprintComponent = UPlayerSprintComponent::GetOrCreate(Player);

		TEMPRootRotation = Player.ActorRotation; // TODO: Remove this line once properly implemented
		
		FootTraceComp.InitializeTraceDataVariable(IKFeetPlacementData);

		bSkipStart = (GetPrevLocomotionAnimationTag() == n"LedgeGrab");

		BankingComp = UHazeAnimPlayerBankingComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		// Implement Custom Stuff Here

		bWantsToMove = !MoveComponent.SyncedMovementInputForAnimationOnly.IsNearlyZero();

		

		CrouchAnimData = CrouchComp.AnimData;
		if(MoveComponent.HorizontalVelocity.Size() <= 10.0)
			bIsStopping = true;
		else
			bIsStopping = false;

		bIsSprinting = SprintComponent.IsSprintToggled();

		Velocity = MoveComponent.Velocity;
		Speed = Velocity.Size();

		//BANKING TEST
		//COPIED from FeatureAnimInstanceMovement. Anything changed in banking logic in reference to regular movement might have repercussions for this AnimInstance.
		
		// Banking calculations
		const float MAX_ADDITIVE_BANKING = 0.25;
		AdditiveBankAlpha = Math::Clamp(Speed / 250 * MAX_ADDITIVE_BANKING, 0.0, MAX_ADDITIVE_BANKING);
		const float NewBanking = Math::Clamp(MoveComponent.GetMovementYawVelocity(true) / 630, -1.0, 1.0);
		float BankInterpSpeed = Math::Abs(Banking) < Math::Abs(NewBanking) ? 15 : 8;

		float NewAdditiveBankValue = 0;
		if (Math::Abs(Banking) < Math::Abs(NewBanking))
			NewAdditiveBankValue = (NewBanking - Banking) * 10;
		AdditiveBanking = Math::FInterpTo(AdditiveBanking, NewAdditiveBankValue, DeltaTime, 7);

		Banking = Math::FInterpTo(Banking, NewBanking, DeltaTime, BankInterpSpeed);

		// TODO: Remove this once the actual capsule rotation is fixed.
		// Also, when the capsule rotation has been updated all banking values will most likely need to be tweaked again to get a good feeling
		TEMPRootRotation = Math::RInterpTo(TEMPRootRotation, Player.ActorRotation, DeltaTime, 10);

		//IK Data
		FootTraceComp.UpdateSlopeWarpData(IKData);
		SlopeRotation = MoveComponent.GetSlopeRotationForAnimation();

		const bool bForceReTraceAllFeet = CheckValueChangedAndSetBool(bEnableIKFeetPlacement, FootTraceComp.AreRequirementsMet(), EHazeCheckBooleanChangedDirection::TrueToFalse);
		if (bEnableIKFeetPlacement)
			FootTraceComp.TraceFeet(IKFeetPlacementData, bForceReTraceAllFeet);
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	// UFUNCTION(BlueprintOverride)
	// float GetBlendTime() const
	// {
	// 	return 0.2; // Implement Custom Stuff Here
	// }

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}
}
