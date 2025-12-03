struct FSiegeProjectileImpact
{
	bool bHitTarget;
	FVector Normal;
}

class ASiegeBaseProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	AActor SpawnInstigator;

	FVector TargetLocation;
	
	float Speed = 9000.0;

	UPROPERTY()
	float TraceRadius = 150.0;

	FSiegeProjectileImpact HitTarget()
	{
		FSiegeProjectileImpact Params;

		// FHazeTraceDebugSettings Debug;
		// Debug.Thickness = 15.0;
		// Debug.TraceColor = FLinearColor::Red;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.IgnoreActor(SpawnInstigator);
		TraceSettings.UseSphereShape(TraceRadius);
		// TraceSettings.DebugDraw(Debug);

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + ActorForwardVector);
		
		if (Hit.bBlockingHit)
		{
			Params.bHitTarget = true; 
			Params.Normal = Hit.Normal;
		}
		
		return Params;
	}
}