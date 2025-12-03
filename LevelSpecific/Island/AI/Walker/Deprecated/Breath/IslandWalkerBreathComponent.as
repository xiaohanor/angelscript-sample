class UIslandWalkerBreathComponent : UNiagaraComponent
{
	UPROPERTY()
	TSubclassOf<AIslandWalkerBreathRing> RingClass;

	default SetFloatParameter(n"VelocityMulti", 2);
	default SetFloatParameter(n"SpriteSizeMin", 500);
	default SetFloatParameter(n"SpriteSizeMax", 600);
	default SetFloatParameter(n"SpawnRate", 45.0);
	default bAutoActivate = false;

	FVector Direction;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetFloatParameter(n"VelocityMulti", 2);
		SetFloatParameter(n"SpriteSizeMin", 500);
		SetFloatParameter(n"SpriteSizeMax", 600);
		SetFloatParameter(n"SpawnRate", 45.0);
	}

	void StartBreath(FVector Dir)
	{
		Direction = Dir;
		WorldRotation = Dir.Rotation();
		Activate();
	}

	void SpawnRing()
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		FHitResult Result = Trace.QueryTraceSingle(WorldLocation, WorldLocation + Direction * 2000);
		if(Result.bBlockingHit)
		{
			AIslandWalkerBreathRing Ring = SpawnActor(RingClass, Result.Location, bDeferredSpawn = true);
			Ring.Owner = Cast<AHazeActor>(Owner);
			FinishSpawningActor(Ring);
		}
	}

	void StopBreath()
	{
		Deactivate();
	}
}