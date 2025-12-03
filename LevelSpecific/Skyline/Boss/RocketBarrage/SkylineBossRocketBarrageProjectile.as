UCLASS(Abstract)
class ASkylineBossRocketBarrageProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RotationPivot;

	UPROPERTY(DefaultComponent, Attach = RotationPivot)
	USceneComponent MeshPivot;

	UPROPERTY(DefaultComponent)
	UTelegraphDecalComponent TargetDecal;
	default TargetDecal.SetAbsolute(true, true, true);
	default TargetDecal.Type = ETelegraphDecalType::Scifi;

	UPROPERTY(DefaultComponent)
	UHazeActorLocalSpawnPoolEntryComponent SpawnPoolEntryComp;

	USkylineBossRocketBarrageComponent RocketBarrageComp;

	FVector2D RotationSpeedSpan = FVector2D(-300.0, 300.0);
	float RotationTargetSpeed = 0.0;
	FHazeAcceleratedFloat RotationSpeed;

	FVector2D RotationRadiusSpan = FVector2D(100.0, 600.0);
	float RotationTargetRadius = 0.0;
	FHazeAcceleratedFloat RotationRadius;

	FSkylineBossRocketBarrageTarget Target;

	TArray<AActor> ActorsToIgnore;

	UPROPERTY(EditAnywhere)
	bool bHomingActive = true;

	UPROPERTY(EditAnywhere)
	float Drag = 1.0;

	UPROPERTY(EditAnywhere)
	float Damage = 0.1;

	UPROPERTY(EditAnywhere)
	float DamageRadius = 1000.0;

	float TimeStamp;
	int PhaseIndex = 0;

	AGravityBikeFree GravityBike;

	FVector SpawnLocation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorEnableCollision(false); 

		SpawnPoolEntryComp.OnSpawned.AddUFunction(this, n"OnSpawned");
		SpawnPoolEntryComp.OnUnspawned.AddUFunction(this, n"OnUnspawned");
	}

	UFUNCTION()
	private void OnSpawned(AHazeActor Actor)
	{
		RotationTargetSpeed = Math::RandRange(RotationSpeedSpan.X, RotationSpeedSpan.Y);
		RotationTargetRadius = Math::RandRange(RotationRadiusSpan.X, RotationRadiusSpan.Y);

		RotationPivot.AddLocalRotation(FRotator(0.0, 0.0, Math::RandRange(0.0, 360.0)));

		TimeStamp = Time::GameTimeSeconds;

		SpawnLocation = ActorLocation;

		USkylineBossRocketBarrageProjectileEventHandler::Trigger_OnLaunch(this);
	}

	UFUNCTION()
	private void OnUnspawned(AHazeActor Actor)
	{
		USkylineBossRocketBarrageProjectileEventHandler::Trigger_OnUnspawn(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector PrevMeshPivotLocation = MeshPivot.WorldLocation;

		RotationSpeed.AccelerateTo(RotationTargetSpeed, 3.0, DeltaSeconds);
		RotationPivot.AddLocalRotation(FRotator(0.0, 0.0, RotationSpeed.Value * DeltaSeconds));
		RotationRadius.AccelerateTo(RotationTargetRadius, 2.0, DeltaSeconds);
		MeshPivot.RelativeLocation = FVector::UpVector * RotationRadius.Value;

		FVector Force;

		FVector ToTarget = Target.Location - ActorLocation;
		Force = ToTarget.SafeNormal * 10000.0;

		// Add a force upwards at the start
		if (Time::GameTimeSeconds - TimeStamp < 1.0)
			Force += FVector::UpVector * 7000.0;

		float ProximityPrecision = 1.0 - Math::GetPercentageBetweenClamped(0.0, 5000.0, ToTarget.Size());

		ActorVelocity = ActorVelocity.SlerpTowards(ToTarget.SafeNormal, ProximityPrecision * 50.0 * DeltaSeconds);
	
		MeshPivot.RelativeLocation = FVector::UpVector * RotationRadius.Value * (1.0 - ProximityPrecision);

		FVector Acceleration = Force
							 - ActorVelocity * Drag;

		ActorVelocity += Acceleration * DeltaSeconds;

		FQuat TargetRotation = ActorQuat;

		if (!Force.IsNearlyZero())
			TargetRotation = Force.ToOrientationQuat();

		FQuat Rotation = FQuat::Slerp(ActorQuat, TargetRotation, 5.0 * DeltaSeconds);
		SetActorRotation(Rotation);

		FVector DeltaMove = ActorVelocity * DeltaSeconds;

		Move(DeltaMove);

		// Update MeshPivot Rotation
		FVector MeshPivotDeltaMove = MeshPivot.WorldLocation - PrevMeshPivotLocation;
		MeshPivot.ComponentQuat = MeshPivotDeltaMove.ToOrientationQuat();

		if (ActorLocation.Z < Target.Location.Z)
		{
			FHitResult HitResult;
			HitResult.Location = ActorLocation;
			HitResult.bBlockingHit = true;
			HandleImpact(HitResult);
		}
	}

	void Move(FVector DeltaMove)
	{
		auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActors(ActorsToIgnore);
		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (HitResult.bBlockingHit)
			HandleImpact(HitResult);
		else
			ActorLocation += DeltaMove;
	}

	void HandleImpact(FHitResult HitResult)
	{
		for (auto Player : Game::Players)
		{
			if (ActorLocation.Distance(Player.ActorLocation) < DamageRadius)
			{
				auto Boss = TListedActors<ASkylineBoss>().Single;
				FPlayerDeathDamageParams Params;
				Params.ImpactDirection = (Player.ActorLocation - ActorLocation).SafeNormal;
				Player.DamagePlayerHealth(0.2, DamageEffect = Boss.DeathDamageComp.ExplosionDamageEffect, DeathEffect = Boss.DeathDamageComp.ExplosionDeathEffect, DeathParams = Params);
			}
		}

		{
			FSkylineBossRocketBarrageOnImpactEventData EventData;
			EventData.Location = HitResult.ImpactPoint;
			EventData.Normal = HitResult.ImpactNormal;
			USkylineBossRocketBarrageProjectileEventHandler::Trigger_OnImpact(this, EventData);
		}

		if (Target.bTargetOnGround)
		{
			// Spawn impact
//			RocketBarrageComp.SpawnRocketImpact(HitResult.ImpactPoint, FRotator::MakeFromZX(HitResult.ImpactNormal, ActorForwardVector));
		}

		SpawnPoolEntryComp.Unspawn();
	}
};