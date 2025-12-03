event void FOnTargetedPlayer();

UCLASS(Abstract)
class AOilRigTransportShipProjectileSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SpawnerRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AOilRigTransportShipProjectile> ProjectileClass;

	UPROPERTY(EditInstanceOnly)
	AOilRigTransportShip TransportShip;

	UPROPERTY()
	FOnTargetedPlayer OnTargetedMio;

	UPROPERTY()
	FOnTargetedPlayer OnTargetedZoe;

	FTimerHandle MioTimerHandle;
	FTimerHandle ZoeTimerHandle;
	FTimerHandle RandomTargetTimerHandle;

	FVector2D PlayerTargetInterval = FVector2D(0.8, 1.4);
	FVector2D RandomTargetInterval = FVector2D(0.2, 0.4);

	float SpawnHeight = 12000.0;

	UFUNCTION()
	void ActivateSpawner()
	{
		ShootAtMio();
		ShootAtZoe();
		SpawnProjectile(nullptr);
	}

	UFUNCTION()
	void DeactivateSpawner()
	{
		MioTimerHandle.ClearTimerAndInvalidateHandle();
		ZoeTimerHandle.ClearTimerAndInvalidateHandle();
		RandomTargetTimerHandle.ClearTimerAndInvalidateHandle();
	}

	void SpawnProjectile(AHazePlayerCharacter TargetPlayer = nullptr)
	{
		FVector SpawnDirection = FVector::UpVector.RotateAngleAxis(20.0, FVector::RightVector);
		SpawnDirection = SpawnDirection.RotateAngleAxis(Math::RandRange(0.0, 360.0), FVector::UpVector);
		FRotator SpawnRot = FRotator::MakeFromZ(SpawnDirection);

		if (TargetPlayer == nullptr)
		{
			FVector TargetLoc = FVector::ZeroVector;
			while (TargetLoc.Equals(FVector::ZeroVector))
			{
				FVector TraceStartLoc = Math::RandomPointInBoundingBox(TransportShip.InheritMovementComp.WorldLocation + (FVector::UpVector * 1000.0), FVector(2800, 1800, 1.0));
				FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
				Trace.IgnorePlayers();
				Trace.UseLine();
				
				FHitResult Hit = Trace.QueryTraceSingle(TraceStartLoc, TraceStartLoc - (FVector::UpVector * 2000.0));
				if (Hit.bBlockingHit)
					TargetLoc = Hit.ImpactPoint;
			}

			AOilRigTransportShipProjectile Projectile = SpawnActor(ProjectileClass, TargetLoc + (SpawnDirection * SpawnHeight), SpawnRot);
			Projectile.AttachToComponent(TransportShip.WobbleRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
			Projectile.StartTargeting(TargetLoc);
			RandomTargetTimerHandle = Timer::SetTimer(this, n"ShootAtRandomTarget", Math::RandRange(RandomTargetInterval.Min, RandomTargetInterval.Max));
		}
		else
		{
			FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
			TraceSettings.IgnorePlayers();
			TraceSettings.UseLine();

			FVector TargetLoc = TargetPlayer.ActorCenterLocation;

			FHitResult PlayerHit = TraceSettings.QueryTraceSingle(TargetLoc, TargetLoc - (FVector::UpVector * 1000.0));
			if (PlayerHit.bBlockingHit)
			{
				AOilRigTransportShipProjectile Projectile = SpawnActor(ProjectileClass, PlayerHit.ImpactPoint + (SpawnDirection * SpawnHeight), SpawnRot);
				Projectile.AttachToComponent(TransportShip.WobbleRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
				Projectile.StartTargeting(PlayerHit.ImpactPoint);
			}

			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(TargetPlayer);
			TargetLoc += MoveComp.HorizontalVelocity;

			FHitResult OffsetHit = TraceSettings.QueryTraceSingle(TargetLoc, TargetLoc - (FVector::UpVector * 1000.0));
			if (OffsetHit.bBlockingHit)
			{
				AOilRigTransportShipProjectile Projectile = SpawnActor(ProjectileClass, OffsetHit.ImpactPoint + (SpawnDirection * SpawnHeight), SpawnRot);
				Projectile.AttachToComponent(TransportShip.WobbleRoot, NAME_None, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
				Projectile.StartTargeting(OffsetHit.ImpactPoint);
			}

			if (TargetPlayer.IsMio())
				MioTimerHandle = Timer::SetTimer(this, n"ShootAtMio", Math::RandRange(PlayerTargetInterval.Min, PlayerTargetInterval.Max));
			else
				ZoeTimerHandle = Timer::SetTimer(this, n"ShootAtZoe", Math::RandRange(PlayerTargetInterval.Min, PlayerTargetInterval.Max));
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ShootAtRandomTarget()
	{
		SpawnProjectile(nullptr);
	}

	UFUNCTION(NotBlueprintCallable)
	void ShootAtMio()
	{
		SpawnProjectile(Game::Mio);

		OnTargetedMio.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	void ShootAtZoe()
	{
		SpawnProjectile(Game::Zoe);
		
		OnTargetedZoe.Broadcast();
	}
}