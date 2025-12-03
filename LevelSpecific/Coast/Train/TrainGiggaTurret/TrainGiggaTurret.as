class ATrainGiggaTurret : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UBoxComponent OverlapBox;

	UPROPERTY()
	TSubclassOf<ATrainGiggaTurretProjectile> GiggaTurretProjectileClass;

	UPROPERTY(DefaultComponent)
	UInteractionComponent Interact;

	UPROPERTY()
	UNiagaraSystem DestroyFX;

	UPROPERTY()
	UAnimSequence PlayerHitTurretAnim;

	bool bTurretActive = false;

	bool bAggroActive = false;
 
	float TimeSinceLastShot = 2.0;

	AHazePlayerCharacter TargetPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverlapBox.OnComponentBeginOverlap.AddUFunction(this, n"BoxOverlapEvent");
		Interact.OnInteractionStarted.AddUFunction(this, n"TurretInteractedWith");
	}

	UFUNCTION()
	void TurretInteractedWith(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		FHazeSlotAnimSettings AnimSettings;
		AnimSettings.BlendTime = 0.2;
		Player.PlaySlotAnimation(PlayerHitTurretAnim, AnimSettings);
		Timer::SetTimer(this, n"DestroyTurret", 0.3, false);
	}

	UFUNCTION()
	void DestroyTurret()
	{
		Niagara::SpawnOneShotNiagaraSystemAttached(DestroyFX, Mesh);
		DestroyActor();
	}

	UFUNCTION()
	void BoxOverlapEvent(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	UPrimitiveComponent OtherComponent, int OtherBodyIndex,
	bool bFromSweep, const FHitResult&in Hit)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			bAggroActive = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (bAggroActive && TimeSinceLastShot >= 5.0)
		{
			TimeSinceLastShot = 0.0;
			FireProjectile();
		}

		TimeSinceLastShot += DeltaSeconds;
	}

	void FireProjectile()
	{
			TArray<AActor> OverlappingPlayers;
			OverlapBox.GetOverlappingActors(OverlappingPlayers, AHazePlayerCharacter);

			if (OverlappingPlayers.Num() == 0)
				return;

			float DistanceToPlayer = 20000.0;

			for (auto Player : OverlappingPlayers)
			{	
				if (GetDistanceTo(Player) < DistanceToPlayer)
				{
					TargetPlayer = Cast<AHazePlayerCharacter>(Player);
					DistanceToPlayer = GetDistanceTo(Player);
				}
			}

		auto Projectile = SpawnActor(GiggaTurretProjectileClass, ActorLocation, FRotator::ZeroRotator, NAME_None, true);
		Projectile.ImpactLocation = TargetPlayer.ActorLocation;
		FVector Direction = TargetPlayer.ActorLocation - ActorLocation;
		FRotator ProjectileRotation = FRotator::MakeFromX(Direction);
		Projectile.StartLocation = GetActorLocation();
		Projectile.TrainTurretRightVector = GetActorRightVector();
		Projectile.TargetPlayer = TargetPlayer;
		Projectile.TrainTurretForwardVector = GetActorForwardVector();
		Projectile.FocusActor = this;
		FinishSpawningActor(Projectile);
		Projectile.SetActorRotation(ProjectileRotation);
	}
}