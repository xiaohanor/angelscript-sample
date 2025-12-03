class ASkylineSentryBossLaserProjectile : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent MeshComp;
	default MeshComp.CollisionEnabled = ECollisionEnabled::NoCollision;


	UPROPERTY(DefaultComponent)
	USkylineSentryBossAlignmentComponent AlignmentComp;

	UPROPERTY(DefaultComponent)
	USkylineSentryBossSphericalMovementComponent SphericalMovementComponent;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SkylineSentryBossAlignMovementCapability");


	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBoxComponent Collision;

	UPROPERTY()
	UNiagaraSystem ImpactNiagaraSystem;


	ASkylineSentryBossLaserDrone LaserDrone;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	

		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseBoxShape(Collision);
		TraceSettings.IgnoreActor(this);
		TraceSettings.IgnoreActor(LaserDrone);
		

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(MeshRoot.WorldLocation, MeshRoot.WorldLocation + ActorForwardVector);

		for(FHitResult Hit : HitArray)
		{
			if(Hit.bBlockingHit)
			{
				if(Hit.Actor == Game::Mio)
					Print("Hit Mio");

				Niagara::SpawnOneShotNiagaraSystemAtLocation(ImpactNiagaraSystem, MeshRoot.WorldLocation, MeshRoot.WorldRotation);
				DestroyActor();
			}
		}
	}

}