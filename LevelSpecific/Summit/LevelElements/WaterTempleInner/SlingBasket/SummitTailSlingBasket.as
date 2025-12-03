class ASummitTailSlingBasket : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.NetworkMode = EFauxPhysicsConeRotateNetworkMode::SyncedFromZoeControl;
	default ConeRotateComp.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent PoleMeshComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent BasketMeshComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UStaticMeshComponent ClimbMeshComp;

	UPROPERTY(DefaultComponent, Attach = ClimbMeshComp)
	UBabyDragonTailClimbFreeFormResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UHazeMovablePlayerTriggerComponent MioInBasketTrigger;
	default MioInBasketTrigger.TriggeredByPlayers = EHazeSelectPlayer::Mio;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactCallbackComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 30000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitTailSlingBasketRetractCapability");

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TailPullBackForceMultiplier = 0.25; 

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TailPullReleaseImpulseForceMultiplier = 2.5; 

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchImpulseMultiplier = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ForwardLaunchFraction = 0.1;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LandOnImpulse = 25.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LeaveImpulse = 25.0;

	bool bTailIsAttached = false;
	bool bMioIsInBasket = false;

	UPlayerMovementComponent MioMovementComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);

		ResponseComp.OnTailAttached.AddUFunction(this, n"OnTailAttached");
		ResponseComp.OnTailReleased.AddUFunction(this, n"OnTailReleased");
		ResponseComp.OnTailJumpedFrom.AddUFunction(this, n"OnTailJumpedFrom");

		MioInBasketTrigger.OnPlayerEnter.AddUFunction(this, n"OnMioEnteredBasket");
		MioInBasketTrigger.OnPlayerLeave.AddUFunction(this, n"OnMioLeftBasket");

		ImpactCallbackComp.OnGroundImpactedByPlayer.AddUFunction(this, n"OnGroundImpactedByPlayer");
		ImpactCallbackComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"OnGroundLeftByPlayer");
	}

	UFUNCTION()
	private void OnGroundImpactedByPlayer(AHazePlayerCharacter Player)
	{
		FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation, FVector::DownVector * LandOnImpulse);
	}

	UFUNCTION()
	private void OnGroundLeftByPlayer(AHazePlayerCharacter Player)
	{
		FauxPhysics::ApplyFauxImpulseToActorAt(this, Player.ActorLocation, FVector::UpVector * LandOnImpulse);
	}

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
	}

	UFUNCTION()
	private void OnTailJumpedFrom(FBabyDragonTailClimbFreeFormJumpedFromParams Params)
	{
		FauxPhysics::ApplyFauxForceToActorAt(this, Params.WorldAttachLocation, Params.JumpVelocity * TailPullReleaseImpulseForceMultiplier);
		if(bMioIsInBasket)
			LaunchMio(Params.JumpVelocity);
	}

	private void LaunchMio(FVector JumpVelocity)
	{
		FVector ImpulseVelocity = (JumpVelocity * LaunchImpulseMultiplier).ConstrainToPlane(ActorForwardVector);
		ImpulseVelocity += -ActorForwardVector * ImpulseVelocity.Size() * ForwardLaunchFraction; 

		Game::Mio.AddMovementImpulse(ImpulseVelocity);

		if(MioMovementComp == nullptr)
			MioMovementComp = UPlayerMovementComponent::Get(Game::Mio);
		MioMovementComp.AddMovementIgnoresActor(this, this);

		Timer::SetTimer(this, n"RemoveMovementIgnore", 0.5);
	}

	UFUNCTION()
	private void RemoveMovementIgnore()
	{
		MioMovementComp.RemoveMovementIgnoresActor(this);
	}
};