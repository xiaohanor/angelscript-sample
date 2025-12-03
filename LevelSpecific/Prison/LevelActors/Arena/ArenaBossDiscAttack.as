UCLASS(Abstract)
class AArenaBossDiscAttack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent DiscRoot;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDeathEffect> DeathEffect;
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UDamageEffect> DamageEffect;

	float MoveSpeed = 3400.0;

	float MaxDuration = 10.0;
	float CurrentDuration = 0.0;

	float TimeOffset = 0.0;

	void LaunchDisc()
	{
		TimeOffset = Math::RandRange(0.0, 1.0);
		UArenaBossDiscEffectEventHandler::Trigger_DiscLaunched(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetActorLocation(ActorLocation + (ActorForwardVector * MoveSpeed * DeltaTime));
		DiscRoot.AddLocalRotation(FRotator(0.0, -450.0 * DeltaTime, 0.0));

		float YOffset = Math::Sin((CurrentDuration + TimeOffset) * 5.0) * 100.0;
		DiscRoot.SetRelativeLocation(FVector(0.0, YOffset, 0.0));

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		Trace.IgnoreActor(this);
		Trace.UseBoxShape(240.0, 240.0, 30.0, FQuat(ActorRotation));
		
		FOverlapResultArray OverlapResults = Trace.QueryOverlaps(DiscRoot.WorldLocation);
		for (FOverlapResult Result : OverlapResults)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Result.Actor);
			if (Player != nullptr)
				Player.DamagePlayerHealth(0.5, FPlayerDeathDamageParams(ActorForwardVector, 5.0), DamageEffect, DeathEffect);
		}

		FHazeTraceSettings CollisionTrace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		CollisionTrace.IgnoreActor(this);
		CollisionTrace.IgnorePlayers();
		CollisionTrace.UseLine();

		FHitResult Hit = CollisionTrace.QueryTraceSingle(ActorLocation, ActorLocation + (ActorForwardVector * 300.0));
		if (Hit.bBlockingHit)
			DestroyDisc();

		CurrentDuration += DeltaTime;
		if (CurrentDuration >= MaxDuration)
			DestroyDisc();
	}

	void DestroyDisc()
	{
		UArenaBossDiscEffectEventHandler::Trigger_DiscDestroyed(this);
		AddActorDisable(this);

		BP_Destroy();
	}

	UFUNCTION(BlueprintEvent)
	void BP_Destroy() {}
}