class AStoneBeastElectricTrap : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotateRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	USceneComponent LightningRoot;

	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UBoxComponent DamageComp1;
	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UBoxComponent DamageComp2;
	UPROPERTY(DefaultComponent, Attach = RotateRoot)
	UBoxComponent DamageComp3;

	UPROPERTY(EditAnywhere)
	float Damage = 0.3;

	UPROPERTY(EditAnywhere)
	ASerpentEventActivator EventActivator;

	UPROPERTY(EditAnywhere)
	bool bStartActive = false;

	FVector StartScaleBall;
	FVector StartScaleLightning;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartScaleBall = MeshRoot.RelativeScale3D;
		MeshRoot.RelativeScale3D = FVector(0.05);
		StartScaleLightning = LightningRoot.RelativeScale3D;
		LightningRoot.RelativeScale3D = FVector(0.05);

		EventActivator.OnSerpentEventTriggered.AddUFunction(this, n"OnSerpentEventTriggered");

		DamageComp1.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		DamageComp2.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		DamageComp3.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");

		if (!bStartActive)
		{
			SetActorTickEnabled(false);
			SetActorHiddenInGame(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RotateRoot.AddLocalRotation(FRotator(0.0, 0.0, 30 * DeltaSeconds));
		// MeshRoot.RelativeScale3D = Math::VInterpTo(MeshRoot.RelativeScale3D, StartScaleBall, DeltaSeconds, 1.0);
		// LightningRoot.RelativeScale3D = Math::VInterpTo(LightningRoot.RelativeScale3D, StartScaleLightning, DeltaSeconds, 1.0);
	}

	UFUNCTION()
	private void OnSerpentEventTriggered()
	{
		BP_ActivateLightning();
		SetActorTickEnabled(true);
		SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintEvent)
	void BP_ActivateLightning()
	{

	}
	
	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr)
		{
			Player.DamagePlayerHealth(Damage);
			Player.AddDamageInvulnerability(this, 1.0);
		}	
	}
};