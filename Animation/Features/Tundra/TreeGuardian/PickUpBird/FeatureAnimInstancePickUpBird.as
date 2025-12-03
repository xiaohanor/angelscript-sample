UCLASS(Abstract)
class UFeatureAnimInstancePickUpBird : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeaturePickUpBird Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeaturePickUpBirdAnimData AnimData;



	UHazeMovementComponent MoveComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	UHazeAnimPlayerLookAtComponent AnimLookAtComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;
 
    // Speed 
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)	
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bPlayGesture;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(BlueprintReadOnly)
	bool IsCarryingBird;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	ETundraPlayerCrackBirdState CurrentState;

	FQuat CachedActorRotation;

	UBigCrackBirdCarryComponent BirdCarryComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		auto ParentPlayer = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		MoveComp = UHazeMovementComponent::Get(ParentPlayer);
		BirdCarryComp = UBigCrackBirdCarryComponent::GetOrCreate(ParentPlayer);

		AnimLookAtComp = UHazeAnimPlayerLookAtComponent::GetOrCreate(HazeOwningActor);
		AnimLookAtComp.SetPlayer(ParentPlayer);
	}

	

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeaturePickUpBird NewFeature = GetFeatureAsClass(ULocomotionFeaturePickUpBird);
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
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;
		
		Speed = MoveComp.Velocity.Size();
		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero()))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}
		
		// Banking
		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);

		CurrentState = BirdCarryComp.GetCurrentState();
		IsCarryingBird = BirdCarryComp.GetBird() != nullptr && BirdCarryComp.GetCurrentState() != ETundraPlayerCrackBirdState::PuttingDown;
		
	}

	UFUNCTION(BlueprintOverride)
	bool CanTransitionFrom() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnUpdateCurrentAnimationStatus(TArray<FName>& OutCurrentAnimationStatus)
	{
		if (bWantsToMove)
			OutCurrentAnimationStatus.Add(n"Moving");
	}
}
