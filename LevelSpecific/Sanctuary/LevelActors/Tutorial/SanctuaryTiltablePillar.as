class ASanctuaryTiltablePillar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UFauxPhysicsForceComponent ForceComp;

	UPROPERTY(DefaultComponent)
	USceneComponent AimLocation;

	UPROPERTY(DefaultComponent)
	USceneComponent GrabLocation;

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UBoxComponent Trigger;
	default Trigger.BoxExtent = FVector(50.0, 50.0, 50.0,);
	default Trigger.bGenerateOverlapEvents = false;
	default Trigger.CollisionResponseToAllChannels = ECollisionResponse::ECR_Ignore;
	default Trigger.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UArrowComponent LaunchDirection;

	UPROPERTY(DefaultComponent)
	UDarkPortalResponseComponent DarkPortalResponseComponent;

	UPROPERTY(DefaultComponent)
	UDarkPortalFauxPhysicsReactionComponent DarkPortalFauxPhysicsReactionComponent;
	
	UPROPERTY(DefaultComponent, Attach = RotateComp)
	UCameraShakeForceFeedbackComponent CameraShakeForceFeedbackComponent;

	UPROPERTY()
	bool bLaunchPlayerOnConstraintHit = false;

	UPROPERTY(EditAnywhere)
	float ImpulseForce = 1000.0;

	bool bHasConstrainedHit = false;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(EditAnywhere)
	ACapabilitySheetVolume SheetVolume;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateComp.OnMinConstraintHit.AddUFunction(this, n"HandleMinConstraintHit");
		RotateComp.OnMaxConstraintHit.AddUFunction(this, n"HandleMaxConstrainHit");
	}

	UFUNCTION()
	private void HandleMaxConstrainHit(float Strength)
	{
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		PrintToScreen("SADASDASDASD", 2.0, FLinearColor::Blue);
		BP_MaxHit();
	}

	UFUNCTION()
	private void HandleMinConstraintHit(float Strength)
	{
		if (bLaunchPlayerOnConstraintHit)
			Launch();
		
		CameraShakeForceFeedbackComponent.ActivateCameraShakeAndForceFeedback();

		BP_MinHit();

		if(SheetVolume != nullptr)
			SheetVolume.DisableForPlayer(Game::Zoe, this);

	}

	void Launch()
	{
	auto Trace = Trace::InitFromPrimitiveComponent(Trigger);
		auto Overlaps = Trace.QueryOverlaps(Trigger.WorldLocation);

		for (auto Overlap : Overlaps)
		{
			auto Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player != nullptr)
			{
				Player.AddMovementImpulse(LaunchDirection.ForwardVector * ImpulseForce);
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_MinHit(){}

	UFUNCTION(BlueprintEvent)
	void BP_MaxHit(){}
};