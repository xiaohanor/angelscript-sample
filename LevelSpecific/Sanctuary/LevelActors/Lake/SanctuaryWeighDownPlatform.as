class ASanctuaryWeighDownPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PlatformRootComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateComp;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent ReturnForceComponent;

	UPROPERTY(DefaultComponent, Attach = TranslateComp)
	UFauxPhysicsForceComponent PlayerWeightForceComponent;

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleClimbActor;

	UPROPERTY(DefaultComponent, Attach = PlatformRootComp)
	UBoxComponent DeathCollision;

	UPROPERTY(EditInstanceOnly)
	AActor MiddleChain;
	FTransform MiddleChainInitialTransform;

	UPROPERTY(DefaultComponent)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY(EditAnywhere)
	float PlayerForce = 2000.0;

	UPROPERTY(EditAnywhere)
	bool bGateUpwards = true;

	UPROPERTY(EditAnywhere)
	bool bActivateOnce = false;
	bool bGoingDown = false;
	UPROPERTY(EditAnywhere)
	bool bIsKillable = false;

	int PlayerWeights = 0;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (MiddleChain != nullptr)
			MiddleChainInitialTransform = MiddleChain.ActorTransform;
	
		PoleClimbActor.OnStartPoleClimb.AddUFunction(this, n"HandleStartPoleClimb");
		PoleClimbActor.OnStopPoleClimb.AddUFunction(this, n"HandleStopPoleClimb");
		TranslateComp.OnConstraintHit.AddUFunction(this, n"HandleOnConstrainHit");
	}

	UFUNCTION()
	private void HandleOnConstrainHit(EFauxPhysicsTranslateConstraintEdge Edge, float HitStrength)
	{
		if(HitStrength>400.0)
			CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		bGoingDown = false;
	}

	UFUNCTION()
	private void HandleStopPoleClimb(AHazePlayerCharacter Player, APoleClimbActor Pole)
	{
		if(!bActivateOnce)
		PlayerWeights++;
		SetPlayerWeight();
		bGoingDown = true;
	}

	UFUNCTION()
	private void HandleStartPoleClimb(AHazePlayerCharacter Player, APoleClimbActor Pole)
	{
		bGoingDown = false;
		PlayerWeights--;
		SetPlayerWeight();
	}

	UFUNCTION()
	private void SetPlayerWeight()
	{
		PlayerWeightForceComponent.Force = FVector::UpVector * PlayerWeights * PlayerForce;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bGateUpwards==true)
		{
			PlatformRootComp.SetRelativeLocation(FVector(0.0, 0.0, TranslateComp.RelativeLocation.Z * -1));

			if (MiddleChain != nullptr)
				MiddleChain.ActorLocation = MiddleChainInitialTransform.Location + MiddleChain.ActorForwardVector * TranslateComp.RelativeLocation.Z;
		}
		else
		{
			PlatformRootComp.SetRelativeLocation(FVector(0.0, 0.0, TranslateComp.RelativeLocation.Z * 1));
			if (MiddleChain != nullptr)
				MiddleChain.ActorLocation = MiddleChainInitialTransform.Location + MiddleChain.ActorForwardVector * TranslateComp.RelativeLocation.Z * -1.0;
		}

		if(bGoingDown && DeathCollision.IsOverlappingActor(Game::Mio) && bIsKillable && TranslateComp.RelativeLocation.Z < -80)
			Game::Mio.KillPlayer(DeathEffect = DeathEffect);

		PrintToScreen("Loc: " + TranslateComp.RelativeLocation.Z);
		
	}
};