class AMeltdownUnderwaterIceProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	float Speed = 2000.0;
	UPROPERTY()
	float Duration = 2.0;
	UPROPERTY()
	UNiagaraSystem ImpactEffect;

	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector DeltaMove = ActorForwardVector * Speed * DeltaSeconds;
		Timer += DeltaSeconds;

		auto Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceMio);
		Trace.IgnoreActor(this);

		auto HitResult = Trace.QueryTraceSingle(ActorLocation, ActorLocation + DeltaMove);

		if (HitResult.bBlockingHit)
		{
			DestroyActor();
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactEffect, HitResult.Location);
			return;
		}
		else if (Timer >= Duration)
		{
			DestroyActor();
			return;
		}

		//Debug::DrawDebugLine(ActorLocation, ActorLocation + ActorForwardVector * 1000.0, FLinearColor::Red);
		ActorLocation += DeltaMove;
	}
};