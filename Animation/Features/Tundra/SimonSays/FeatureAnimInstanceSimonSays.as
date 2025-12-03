UCLASS(Abstract)
class UFeatureAnimInstanceSimonSays : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureSimonSays Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureSimonSaysAnimData AnimData;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float CurrentTurnRate = 0.0;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsJumping;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFalling;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccess;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSuccessTick;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bFail;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsMonkeyKing;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector PreviousVelocity;

	UTundra_SimonSaysAnimDataComponent SimonSaysAnimComp;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		if (HazeOwningActor == nullptr)
			return;

		AHazeActor OwnerActor = Cast<AHazePlayerCharacter>(HazeOwningActor.AttachParentActor);
		bIsMonkeyKing = OwnerActor == nullptr;
		
		if(bIsMonkeyKing)
			OwnerActor = HazeOwningActor;

		SimonSaysAnimComp = UTundra_SimonSaysAnimDataComponent::GetOrCreate(OwnerActor);

		auto PhysComp = UHazePhysicalAnimationComponent::Get(HazeOwningActor);
		if (PhysComp != nullptr)
			PhysComp.bAllowInSequence = true;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureSimonSays NewFeature = GetFeatureAsClass(ULocomotionFeatureSimonSays);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		CurrentTurnRate = SimonSaysAnimComp.AnimData.CurrentTurnRate;
		bIsJumping = SimonSaysAnimComp.AnimData.bIsJumping;
		bFalling = SimonSaysAnimComp.AnimData.bIsFalling;

		bSuccessTick = !bSuccess && SimonSaysAnimComp.AnimData.bIsSuccess;
		bSuccess = SimonSaysAnimComp.AnimData.bIsSuccess;

		if (bIsJumping)
			Velocity = HazeOwningActor.ActorVelocity.GetSafeNormal();
		if (bFalling || bIsJumping)
			bFail = false;
		else 
			bFail = SimonSaysAnimComp.AnimData.bIsFail;
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
}
