UCLASS(Abstract)
class UFeatureAnimInstanceRainbowPigMovement : UHazeFeatureSubAnimInstance
{
	// The Feature associated with this Feature Sub Anim Instance
	UPROPERTY(Transient, BlueprintHidden, NotEditable)
	ULocomotionFeatureRainbowPigMovement Feature;

	// Read all Feature Anim Data from this struct in the Anim Graph
	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FLocomotionFeatureRainbowPigMovementAnimData AnimData;

	UHazeMovementComponent MoveComp;
	UHazePhysicalAnimationComponent PhysAnimComp;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bWantsToMove;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Speed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float Banking;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	float StoppingSpeed;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bSkipStart;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bUseSlopeRot = true;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FRotator SlopeRotation;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	FVector SlopeOffset;

	UPROPERTY(BlueprintReadOnly, Category = "Physics")
	UHazePhysicalAnimationProfile PhysAnimProfile;

	UHazeAnimSlopeAlignComponent SlopeAlignComp;
	UPlayerPigSiloComponent PlayerPigSiloComp;

	FQuat CachedActorRotation;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		MoveComp = UHazeMovementComponent::Get(HazeOwningActor);
		PhysAnimComp = UHazePhysicalAnimationComponent::GetOrCreate(HazeOwningActor);
		SlopeAlignComp = UHazeAnimSlopeAlignComponent::GetOrCreate(HazeOwningActor);
		PlayerPigSiloComp = UPlayerPigSiloComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		ULocomotionFeatureRainbowPigMovement NewFeature = GetFeatureAsClass(ULocomotionFeatureRainbowPigMovement);
		if (Feature != NewFeature)
		{
			Feature = NewFeature;
			AnimData = NewFeature.AnimData;
		}

		if (Feature == nullptr)
			return;

		bSkipStart = GetAnimBoolParam(n"SkipMovementStart", true);

		CachedActorRotation = HazeOwningActor.ActorQuat;

		SlopeAlignComp.InitializeSlopeTransformData(SlopeOffset, SlopeRotation);

		PhysAnimComp.ApplyProfileAsset(this, PhysAnimProfile);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Feature == nullptr)
			return;

		bool bOverrideMovementInput = false;
		UPlayerPigSiloComponent PigSiloComponent = UPlayerPigSiloComponent::Get(Player);
		if (PigSiloComponent != nullptr)
			if (PigSiloComponent.IsSiloMovementActive())
				bOverrideMovementInput = true;

		Speed = MoveComp.Velocity.Size() * (bOverrideMovementInput ? 10.0 : 1.0);

		if (CheckValueChangedAndSetBool(bWantsToMove, !MoveComp.SyncedMovementInputForAnimationOnly.IsNearlyZero() || bOverrideMovementInput))
		{
			if (!bWantsToMove)
			{
				// Called when user let's go of the stick
				StoppingSpeed = Speed;
			}
		}

		Banking = CalculateAnimationBankingValue(HazeOwningActor, CachedActorRotation, DeltaTime, Feature.MaxTurnSpeed);

		SlopeAlignComp.GetSlopeTransformData(SlopeOffset, SlopeRotation, DeltaTime, 0.8);
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
