event void FOnMissileTurretDestroy();


class ASkylineSentryBossMissileTurret : AHazeActor
{
	FOnMissileTurretDestroy OnTurretDestroy;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent Aim;

	ASKylineSentryBoss Boss;

	UPROPERTY()
	TSubclassOf<ASkylineSentryBossMissile> ProjectileClass;

	UPROPERTY(EditAnywhere)
	float FireCooldown = 8;
	float TimeToFire;

	int HitPoints = 3;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TimeToFire = Time::GameTimeSeconds + (FireCooldown / 2);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Direction = Game::Mio.ActorLocation - ActorLocation;
		if(Direction.Size() > 350)
		{
			ActorRotation = FRotator::MakeFromZX(ActorUpVector, Direction);

		}

		if(TimeToFire > Time::GameTimeSeconds)
			return;
			
		TimeToFire = Time::GameTimeSeconds + FireCooldown;
		
		AActor SpawnedActor = SpawnActor(ProjectileClass, Aim.WorldLocation, Aim.WorldRotation, NAME_None, true);
		ASkylineSentryBossMissile Projectile = Cast<ASkylineSentryBossMissile>(SpawnedActor);
		Projectile.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		Projectile.Boss = Boss;
		Projectile.SphericalMovementComponent.SetOrigin(Boss.Root);
		
		FTransform SpawnTransform;
		SpawnTransform.Location = Aim.WorldLocation;
		SpawnTransform.Rotation = (ActorRotation + FRotator(0, 0, -90)).Quaternion();
		FinishSpawningActor(SpawnedActor, SpawnTransform);
		
	}



	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		OnTurretDestroy.Broadcast();

	}



}