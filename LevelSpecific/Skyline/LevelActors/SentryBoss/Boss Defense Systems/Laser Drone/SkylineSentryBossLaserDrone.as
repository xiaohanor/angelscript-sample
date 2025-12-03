event void FOnLaserDroneDestroy();


class ASkylineSentryBossLaserDrone : AHazeActor
{
	FOnLaserDroneDestroy OnLaserDroneDestroy;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent Aim;

	UPROPERTY(DefaultComponent)
	USkylineSentryBossAlignmentComponent AlignmentComp;

	UPROPERTY(DefaultComponent)
	USkylineSentryBossSphericalMovementComponent SphericalMoveComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossAlignMovementCapability");


	UPROPERTY(DefaultComponent)
	UGravityBladeCombatResponseComponent ResponseComp;

	ASKylineSentryBoss Boss;

	UPROPERTY()
	TSubclassOf<ASkylineSentryBossLaserProjectile> ProjectileClass;

	float FireCooldown = 5;
	float TimeToFire;
	float HitPoints = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ResponseComp.OnHit.AddUFunction(this, n"OnHit");
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

		if(!IsPlayerWithinRange())
		{
			AlignmentComp.bIsMoving = true;
			return;
		}

		AlignmentComp.bIsMoving = false;


		if(TimeToFire > Time::GameTimeSeconds)
			return;
			
		TimeToFire = Time::GameTimeSeconds + FireCooldown;
		
		AActor SpawnedActor = SpawnActor(ProjectileClass, Aim.WorldLocation, ActorRotation, NAME_None, true);
		ASkylineSentryBossLaserProjectile Projectile = Cast<ASkylineSentryBossLaserProjectile>(SpawnedActor);
		Projectile.SphericalMovementComponent.SetOrigin(Boss.Root);

		Projectile.AttachToActor(Boss, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		
		FTransform SpawnTransform;
		SpawnTransform.Location = Aim.WorldLocation;
		SpawnTransform.Rotation = ActorRotation.Quaternion();
		Projectile.LaserDrone = this;
		FinishSpawningActor(SpawnedActor, SpawnTransform);
	
	}

	UFUNCTION()
	private void OnHit(UGravityBladeCombatUserComponent CombatComp, FGravityBladeHitData HitData)
	{
		HitPoints--;

		if(HitPoints <= 0)
			DestroyActor();

	}


	UFUNCTION(BlueprintOverride)
	void Destroyed()
	{
		OnLaserDroneDestroy.Broadcast();

	}

	bool IsPlayerWithinRange()
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseSphereShape(1500);
		TraceSettings.IgnoreActor(this);

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(ActorLocation, ActorLocation + ActorForwardVector);

		for(FHitResult Hit : HitArray)
		{
			if(Hit.bBlockingHit)
			{
				if(Hit.Actor == Game::Mio)
					return true;
			}

		}

		return false;
	}


};