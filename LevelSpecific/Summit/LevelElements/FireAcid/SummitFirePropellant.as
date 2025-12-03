class ASummitFirePropellant : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent FireBox;

	UPROPERTY(DefaultComponent)
	UAcidResponseComponent AcidResponse;

	UPROPERTY(DefaultComponent)
	UBoxComponent PlayerBox;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent FirePuddle;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireThing;
	default FireThing.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FireExplodeComp;
	default FireExplodeComp.SetAutoActivate(false);

	ATeenDragon PlayerChar;

	float BurningPower = 0.0;

	UPROPERTY(EditAnywhere)
	float BurningSpeed = 2.0;

	float BurningTreshold = 50.0;

	float BurningDecay = 15.0;
	
	bool bFireCooldown = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcidResponse.OnAcidHit.AddUFunction(this, n"OnAcidHit");
		PlayerBox.OnComponentBeginOverlap.AddUFunction(this, n"ImpulseCollider");
		PlayerBox.OnComponentEndOverlap.AddUFunction(this, n"ImpulseColliderExit");
		
	}


	UFUNCTION()
	private void ImpulseCollider(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                             UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                             const FHitResult&in SweepResult)
	{
		FireExplode();
		ATeenDragon EnterDragon = Cast<ATeenDragon>(OtherActor);

		if (EnterDragon != nullptr)
			PlayerChar = EnterDragon;
	}

	UFUNCTION()
	private void ImpulseColliderExit(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                 UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		ATeenDragon EnterDragon = Cast<ATeenDragon>(OtherActor);
		
		if (EnterDragon != nullptr)
			PlayerChar = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		BurningPower = Math::Clamp(BurningPower - BurningDecay * DeltaSeconds, 0.0, 50.0);

		if (BurningPower == 0.0)
			bFireCooldown = false;

		if (BurningPower >= BurningTreshold)
		{
			FireExplode();
			bFireCooldown = true;
		}	

	}
	

	UFUNCTION()
	private void OnAcidHit(FAcidHit Hit)
	{

		if (bFireCooldown == true)
			return;

		BurningPower += BurningSpeed;

		FireThing.Activate();
	}

	UFUNCTION()
	void FireExplode()
	{
		FireExplodeComp.Activate();

		if (PlayerChar == nullptr)
			return;

		PlayerChar.SetActorVelocity(FVector::ZeroVector);
		FVector Impulse;
		Impulse += PlayerChar.ActorForwardVector * 3000.0;
		Impulse += PlayerChar.ActorUpVector * 5000.0;
		PlayerChar.AddMovementImpulse(Impulse); 
	}
}