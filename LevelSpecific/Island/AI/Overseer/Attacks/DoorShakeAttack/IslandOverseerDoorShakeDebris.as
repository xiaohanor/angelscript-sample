class AIslandOverseerDoorShakeDebris : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent MeshOffset;

	UPROPERTY(DefaultComponent)
	USphereComponent Collision;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;

	UPROPERTY(DefaultComponent)
	UIslandRedBlueImpactResponseComponent RedBlueImpactComp;

	UPROPERTY(DefaultComponent)
	UIslandOverseerRedBlueDamageComponent OverseerRedBlueDamageComp;

	UPROPERTY()
	TSubclassOf<UDamageEffect> DamageEffect;

	UPROPERTY()
	TSubclassOf<UDeathEffect> DeathEffect;

	float Speed = 1000;
	FHazeAcceleratedFloat AccSpeed;

	float DamagePerSecond = 6;
	float Health = 1;

	AAIIslandOverseer Overseer;
	FRotator Rotation;
	float RotationSpeed;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OverseerRedBlueDamageComp.OnDamage.AddUFunction(this, n"Damage");
		UIslandOverseerDoorShakeDebrisEventHandler::Trigger_OnSpawn(this);
		Rotation = Math::RandomRotator(true);
		RotationSpeed = Math::RandRange(1.5, 3);
	}

	UFUNCTION()
	private void Damage(float Damage, AHazeActor Instigator)
	{
		Health -= Damage * DamagePerSecond;
		if(Health > 0)
			return;
		
		UIslandOverseerDoorShakeDebrisEventHandler::Trigger_OnImpact(this);

		FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Params;
		Params.AttackLocation = ActorLocation;

		UIslandOverseerEventHandler::Trigger_OnDoorShakeDebrisImpact(Overseer, Params);
		AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		AccSpeed.AccelerateTo(Speed, 1, DeltaSeconds);
		FVector Delta = FVector::DownVector * DeltaSeconds * AccSpeed.Value;

		if(Delta.IsNearlyZero())
			return;
		
		SetActorLocation(ActorLocation + Delta);

		MeshOffset.AddLocalRotation(Rotation * DeltaSeconds * RotationSpeed);

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseSphereShape(Collision);
		FHitResult Hit = Trace.QueryTraceSingle(ActorLocation, ActorLocation + Delta);

		if(Hit.bBlockingHit)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if(Player != nullptr)
			{
				Player.DamagePlayerHealth(0.5, DamageEffect = DamageEffect, DeathEffect = DeathEffect);
				UIslandOverseerDoorShakeDebrisEventHandler::Trigger_OnHit(this, FIslandOverseerDoorShakeDebrisEventHandlerOnHit(Player));
			}

			UIslandOverseerDoorShakeDebrisEventHandler::Trigger_OnImpact(this);

			FIslandOverseerEventHandlerOnDoorShakeAttackImpactData Params;
			Params.AttackLocation = ActorLocation;

			UIslandOverseerEventHandler::Trigger_OnDoorShakeDebrisImpact(Overseer, Params);
			AddActorDisable(this);
		}
	}
}