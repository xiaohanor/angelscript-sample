class ASanctuaryWeeperKillingEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UNiagaraComponent NiagaraComp;

	UPROPERTY(DefaultComponent)
	UCapsuleComponent LaserCollision;




	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeTraceSettings TraceSettings = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
		TraceSettings.UseCapsuleShape(LaserCollision);
		TraceSettings.IgnoreActor(this);

		FHitResultArray HitArray = TraceSettings.QueryTraceMulti(LaserCollision.WorldLocation, LaserCollision.WorldLocation + ActorForwardVector);

		for(FHitResult Hit : HitArray)
		{
			if(Hit.bBlockingHit)
			{
				auto Weeper = Cast<AAISanctuaryWeeper2D>(Hit.Actor);
				
				if(Weeper != nullptr)
				{
					Weeper.DestroyActor();
				}

			}

		}
	}



};