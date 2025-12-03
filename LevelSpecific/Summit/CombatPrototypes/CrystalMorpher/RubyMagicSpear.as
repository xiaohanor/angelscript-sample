class ARubyMagicSpear : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	UPROPERTY()
	UNiagaraSystem ImpactSystem;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorLocation += -FVector::UpVector * 3500.0 * DeltaSeconds;

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_WorldDynamic);
		TraceSettings.IgnoreActor(this);
		TraceSettings.UseLine();

		FHitResult Hit = TraceSettings.QueryTraceSingle(ActorLocation, ActorLocation + -FVector::UpVector * 100.0);

		if (Hit.bBlockingHit)
		{
			Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactSystem, Hit.ImpactPoint);
			DestroyActor();
		}
	}
}