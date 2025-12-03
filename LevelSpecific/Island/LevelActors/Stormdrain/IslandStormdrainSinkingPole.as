class AIslandStormdrainSinkingPole : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsTranslateComponent TranslateRoot;

	UPROPERTY(DefaultComponent, Attach = TranslateRoot)
	USceneComponent PoleRoot;

	UPROPERTY(DefaultComponent, Attach = PoleRoot)
	UStaticMeshComponent PoleMesh;

	// UPROPERTY(DefaultComponent, Attach = PoleRoot)
	// USceneComponent PerchRoot;

	// UPROPERTY(DefaultComponent, Attach = PerchRoot)
	// UPerchPointComponent PerchPointComp;

	// UPROPERTY(DefaultComponent, Attach = PerchPointComp)
	// UPerchEnterByZoneComponent PerchEnterComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 2500.0;

	UPROPERTY(EditInstanceOnly)
	APoleClimbActor PoleClimbActor;

	UPROPERTY(EditAnywhere)
	bool bSink = true;

	bool bPlayerOnPole = false;
	FVector StartPosition;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(PoleClimbActor != nullptr)
		{
			PoleClimbActor.RootComp.SetMobility(EComponentMobility::Movable);
			PoleClimbActor.Pole.SetMobility(EComponentMobility::Movable);
			PoleClimbActor.AttachToComponent(PoleRoot, AttachmentRule = EAttachmentRule::KeepWorld);
			PoleClimbActor.PerchPointComp.OnPlayerStartedPerchingEvent.AddUFunction(this, n"StartedPerching");
			PoleClimbActor.PerchPointComp.OnPlayerStoppedPerchingEvent.AddUFunction(this, n"StoppedPerching");
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void StartedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (bSink)
		{
			bPlayerOnPole = true;
			TranslateRoot.ApplyImpulse(TranslateRoot.WorldLocation, -FVector::UpVector * 200.0);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void StoppedPerching(AHazePlayerCharacter Player, UPerchPointComponent PerchPoint)
	{
		if (bSink)
		{
			bPlayerOnPole = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPlayerOnPole)
			TranslateRoot.ApplyForce(TranslateRoot.WorldLocation + (FVector::UpVector * 50.0), -FVector::UpVector * 100.0);
	}
};