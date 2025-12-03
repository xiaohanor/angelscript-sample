class ASummitTailCatapultBasket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent CatapultRotateRoot;

	UPROPERTY(DefaultComponent, Attach = CatapultRotateRoot)
	UStaticMeshComponent BasketMeshComp;

	UPROPERTY(DefaultComponent, Attach = CatapultRotateRoot)
	UStaticMeshComponent ClimbMeshComp;

	UPROPERTY(DefaultComponent, Attach = CatapultRotateRoot)
	UPlayerInheritMovementComponent InheritMovementComp;

	UPROPERTY(DefaultComponent, Attach = ClimbMeshComp)
	UBabyDragonTailClimbFreeFormResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = CatapultRotateRoot)
	UHazeMovablePlayerTriggerComponent MioInBasketTrigger;
	default MioInBasketTrigger.TriggeredByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformTempLogComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitTailCatapultBasketRetractCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitTailCatapultBasketReleaseCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitTailCatapultBasketResetCapability");

	UPROPERTY(EditAnywhere, Category = "Settings|Pull Back")
	float PullBackMaxDegrees = 15.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Pull Back")
	float PullBackDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float IdleGoBackDuration = 5.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float ReleaseDuration = 0.2;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float MaxGoBackDelay = 0.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float ReleasedRotationDegrees = 20.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float ReleaseMaxImpulseForward = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float ReleaseMaxImpulseUpwards = 2000.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float ZoeBackwardsImpulseSize = 200.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	UForceFeedbackEffect LaunchRumble;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	TSubclassOf<UCameraShakeBase> LaunchCameraShake;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float LaunchShakeInnerRadius = 500.0;

	UPROPERTY(EditAnywhere, Category = "Settings|Release")
	float LaunchShakeOuterRadius = 1000.0;

	float GoBackTimeStamp;

	bool bTailIsAttached = false;
	bool bMioIsInBasket = false;
	bool bIsReleasing = false;

	UPlayerMovementComponent MioMovementComp;

	FHazeAcceleratedRotator AccRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		AccRotation.SnapTo(CatapultRotateRoot.WorldRotation);

		ResponseComp.OnTailAttached.AddUFunction(this, n"OnTailAttached");
		ResponseComp.OnTailReleased.AddUFunction(this, n"OnTailReleased");

		MioInBasketTrigger.OnPlayerEnter.AddUFunction(this, n"OnMioEnteredBasket");
		MioInBasketTrigger.OnPlayerLeave.AddUFunction(this, n"OnMioLeftBasket");
	}

	FRotator GetPulledBackRotation() const property
	{
		const FVector Forward = ActorForwardVector.RotateAngleAxis(PullBackMaxDegrees, CatapultRotateRoot.RightVector);
		return FRotator::MakeFromXY(Forward, CatapultRotateRoot.RightVector);
	}

	FRotator GetReleasedRotation() const property
	{
		const FVector Forward = ActorForwardVector.RotateAngleAxis(-ReleasedRotationDegrees, CatapultRotateRoot.RightVector);
		return FRotator::MakeFromXY(Forward, CatapultRotateRoot.RightVector);
	}

	float GetPulledBackAlpha() const property
	{
		const float CurrentPitch = CatapultRotateRoot.WorldRotation.Pitch;
		return Math::GetPercentageBetween(ActorRotation.Pitch, PulledBackRotation.Pitch, CurrentPitch);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugDirectionArrow(ActorLocation, PulledBackRotation.ForwardVector, 1000.0, 5000, FLinearColor::Red, 10, 0, true);
		Debug::DrawDebugString(ActorLocation + PulledBackRotation.ForwardVector * 1000.0, "Pulled Back Location", FLinearColor::Red);

		Debug::DrawDebugDirectionArrow(ActorLocation, ReleasedRotation.ForwardVector, 1000.0, 5000, FLinearColor::Blue, 10, 0, true);
		Debug::DrawDebugString(ActorLocation + ReleasedRotation.ForwardVector * 1000.0, "Released Location", FLinearColor::Blue);

		FLinearColor InnerShakeRadiusColor = FLinearColor::LucBlue;
		Debug::DrawDebugSphere(ClimbMeshComp.WorldLocation, LaunchShakeInnerRadius, 12, InnerShakeRadiusColor, 10);
		Debug::DrawDebugString(ClimbMeshComp.WorldLocation + FVector::UpVector * LaunchShakeInnerRadius, "Shake Inner Radius", InnerShakeRadiusColor);

		FLinearColor OuterShakeRadiusColor = FLinearColor::DPink;
		Debug::DrawDebugSphere(ClimbMeshComp.WorldLocation, LaunchShakeOuterRadius, 12, OuterShakeRadiusColor, 10);
		Debug::DrawDebugString(ClimbMeshComp.WorldLocation + FVector::UpVector * LaunchShakeOuterRadius, "Shake Outer Radius", OuterShakeRadiusColor);
	}
#endif

	UFUNCTION()
	private void OnMioEnteredBasket(AHazePlayerCharacter Player)
	{
		bMioIsInBasket = true;
	}

	UFUNCTION()
	private void OnMioLeftBasket(AHazePlayerCharacter Player)
	{
		bMioIsInBasket = false;
	}

	UFUNCTION()
	private void OnTailAttached(FBabyDragonTailClimbFreeFormAttachParams Params)
	{
		bTailIsAttached = true;
	}

	UFUNCTION()
	private void OnTailReleased(FBabyDragonTailClimbFreeFormReleasedParams Params)
	{
		bTailIsAttached = false;
		FVector BackwardsImpulse = ActorForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal() * ZoeBackwardsImpulseSize; 
		auto ZoeMoveComp = UPlayerMovementComponent::Get(Game::Zoe);
		auto TailComp = UPlayerTailBabyDragonComponent::Get(Game::Zoe);
		TailComp.bDisableWallStickInitially = true;
		ZoeMoveComp.AddPendingImpulse(BackwardsImpulse);
		Game::Zoe.BlockCapabilities(CapabilityTags::MovementInput, this);
		Timer::SetTimer(this, n"UnblockMovementInputForZoe", 0.75);
	}

	UFUNCTION()
	void UnblockMovementInputForZoe()
	{
		Game::Zoe.UnblockCapabilities(CapabilityTags::MovementInput, this);
	}
};