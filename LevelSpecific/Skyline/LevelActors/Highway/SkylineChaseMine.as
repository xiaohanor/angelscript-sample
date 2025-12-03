class ASkylineChaseMine : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USphereComponent ActivationRange;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	default Mesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USphereComponent Collider;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UStaticMeshComponent FieldMesh;
	default FieldMesh.SetCollisionProfileName(n"NoCollision");

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USkylineFlyingCarRifleTargetableComponent RifleTargetableComponent;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	USkylineFlyingCarBazookaTargetableComponent BazookaTargetableComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthComponent HealthComponent;

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComponent;
	default HealthBarComponent.SetPlayerVisibility(EHazeSelectPlayer::Mio);


	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComponent;


	UPROPERTY()
	UNiagaraSystem ExplosionNiagaraSystem;

	UPROPERTY(EditAnywhere, Meta = (ClampMin = 0.0, ClampMax = 1.0))
	float DamageAmount = 0.3;


	UPROPERTY(EditDefaultsOnly, Category = "UI")
	FVector HealthBarWidgetOffset = FVector::UpVector * 400;


	UFUNCTION(BlueprintEvent)
	void TriggerExplosionAudio() {}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Set control side to driving player
		SetActorControlSide(FlyingCar::GetPilotPlayer());

		auto HealthBarSettings = UBasicAIHealthBarSettings::GetSettings(this);
		HealthBarSettings.HealthBarOffset = HealthBarWidgetOffset;

		HealthComponent.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");

		ActivationRange.OnComponentBeginOverlap.AddUFunction(this, n"OnActivationRangeBeginOverlap");
		ActivationRange.OnComponentEndOverlap.AddUFunction(this, n"OnActivationRangeEndOverlap");
		Collider.OnComponentBeginOverlap.AddUFunction(this, n"OnColliderBeginOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Check if mine is behind player
		AHazePlayerCharacter GunnerPlayer = FlyingCar::GetGunnerPlayer();
		FVector MineToPlayer = GunnerPlayer.ActorLocation - ActorLocation;
		if (GunnerPlayer.ActorForwardVector.DotProduct(MineToPlayer.GetSafeNormal()) > 0.2)
		{
			if (MineToPlayer.SizeSquared() > Math::Square(1000))
			{
				SetActorTickEnabled(false);
				HealthBarComponent.SetHealthBarEnabled(false);
			}
		}
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		if (HasControl())
		{
			if (HealthComponent.IsDead())
				CrumbExplode();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActivationRangeBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (!OtherActor.IsA(ASkylineFlyingCar))
			return;

		SetActorTickEnabled(true);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnActivationRangeEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (!OtherActor.IsA(ASkylineFlyingCar))
			return;

		SetActorTickEnabled(false);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnColliderBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep, const FHitResult&in SweepResult)
	{

		if (!HasControl())
			return;

		ASkylineFlyingCar FlyingCar = Cast<ASkylineFlyingCar>(OtherActor);
		if (FlyingCar == nullptr)
			return;

		CrumbCarImpact(FlyingCar);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbCarImpact(ASkylineFlyingCar FlyingCar)
	{
		FSkylineFlyingCarDamage CarDamage;
		CarDamage.Amount = DamageAmount;
		FlyingCar.TakeDamage(CarDamage);
		FlyingCar.Gunner.PlayCameraShake(FlyingCar.LightCollisionCameraShake, this);
		FlyingCar.Pilot.PlayCameraShake(FlyingCar.LightCollisionCameraShake, this);

		Explode();
	}

	UFUNCTION(CrumbFunction)
	private void CrumbExplode() { Explode(); }	
	private void Explode()
	{
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionNiagaraSystem, MeshRoot.WorldLocation);
		TriggerExplosionAudio();

		DestroyActor();
	}
}