class AMeltdownScreenWalkBungee : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UFauxPhysicsTranslateComponent TranslateRoot;
	default TranslateRoot.SpringStrength = 20.0;
	default TranslateRoot.bConstrainY = true;
	default TranslateRoot.bConstrainZ = true;
	default TranslateRoot.MinZ = -200;
	default TranslateRoot.MaxZ = 200;
	default TranslateRoot.bConstrainX = true;
	default TranslateRoot.MinX = -200;
	default TranslateRoot.MaxX = 200;
	default TranslateRoot.NetworkMode = EFauxPhysicsTranslateNetworkMode::SyncedFromActorControl;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerLaunchBox;
	default PlayerLaunchBox.CollisionEnabled = ECollisionEnabled::QueryOnly;
	default PlayerLaunchBox.CollisionProfileName = n"OverlapAllDynamic";
	default PlayerLaunchBox.bGenerateOverlapEvents = false;
	default PlayerLaunchBox.RelativeLocation = FVector(0, 0, 100);
	default PlayerLaunchBox.BoxExtent = FVector(100);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LaunchPlatform;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeight;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;
	default ResponseComp.bApplySuckToFauxPhysics = true;
	default ResponseComp.TriggerShape = FHazeShapeSettings::MakeSphere(100.0);

	UPROPERTY(EditAnywhere)
	float PlatformSnapStrength = 1000.0;
	UPROPERTY(EditAnywhere)
	float PlayerLaunchStrength = 2000.0;
	UPROPERTY(EditAnywhere)
	float SnapMaxRadius = 200.0;

	private float StartingSpringStrength = 0.0;
	private bool bIsAttached = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		TranslateRoot.OverrideNetworkSyncRate(EHazeCrumbSyncRate::PlayerSynced);

		StartingSpringStrength = TranslateRoot.SpringStrength;
		ResponseComp.OnStompedTrigger.AddUFunction(this, n"OnStartAttach");
		ResponseComp.OnStompReleasedTrigger.AddUFunction(this, n"OnStopAttach");
	}

	UFUNCTION()
	private void OnStopAttach()
	{
		bIsAttached = false;
		TranslateRoot.SpringStrength = StartingSpringStrength;

		SetActorControlSide(Game::Mio);

		FVector Origin = TranslateRoot.SpringParentOffset;
		FVector Direction = (Origin - TranslateRoot.WorldLocation).GetSafeNormal();

		float SnapPct = Origin.Distance(TranslateRoot.WorldLocation) / SnapMaxRadius;
		TranslateRoot.ApplyImpulse(TranslateRoot.WorldLocation, Direction * PlatformSnapStrength * SnapPct);

		if (PlayerLaunchBox.TraceOverlappingComponent(Game::Mio.CapsuleComponent))
		{
			Game::Mio.AddMovementImpulse(Direction * PlayerLaunchStrength * SnapPct);
			Game::Mio.KeepLaunchVelocityDuringAirJumpUntilLanded();
		}
	}

	UFUNCTION()
	private void OnStartAttach()
	{
		SetActorControlSide(Game::Zoe);

		bIsAttached = true;
		TranslateRoot.SpringStrength = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
	}
};