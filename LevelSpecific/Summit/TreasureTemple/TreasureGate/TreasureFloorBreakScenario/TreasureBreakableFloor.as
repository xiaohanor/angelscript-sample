class ATreasureBreakableFloor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UNiagaraSystem BreakVFX;

	TArray<UStaticMeshComponent> MeshComps;

	float BreakTime;
	float BreakDuration = 2.2;

	bool bRemovePhysics;

	float ScaleTime;
	float ScaleDuration = 0.01;

	bool bBroken;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		GetComponentsByClass(MeshComps);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (Time::GameTimeSeconds > BreakTime)
		{
			if (bRemovePhysics && Time::GameTimeSeconds > ScaleTime)
			{
				DestroyActor();
				return;
			}

			for (UStaticMeshComponent Mesh : MeshComps)
			{
				if (!bRemovePhysics)
				{
					Mesh.SetSimulatePhysics(false);
					Mesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

				}
				
				// FVector Scale = Mesh.GetWorldScale();
				// Scale *= 0.99;
				// Mesh.SetWorldScale3D(Scale);
				// Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakVFX, Mesh.GetWorldLocation());
				// BP_BreakFloor();
				// SetActorTickEnabled(false);
				
				
			}	

			if (!bRemovePhysics)
			{
				bRemovePhysics = true;
				ScaleTime = Time::GameTimeSeconds + ScaleDuration;
			}
		}
	}

	UFUNCTION()
	void BreakFloor()
	{
		if (bBroken)
			return;

		bBroken = true;

		for (UStaticMeshComponent Mesh : MeshComps)
		{
			Mesh.SetSimulatePhysics(true);
			Mesh.AddImpulse(-FVector::UpVector * 8000.0);
								Niagara::SpawnOneShotNiagaraSystemAtLocation(BreakVFX, Mesh.GetWorldLocation());

		}

		BreakTime = Time::GameTimeSeconds + BreakDuration;
		float InnerDist = 1000.0;
		float OuterDist = 4000.0;
		Game::Mio.PlayWorldCameraShake(CameraShake, this, ActorLocation, InnerDist, OuterDist);
		Game::Zoe.PlayWorldCameraShake(CameraShake, this, ActorLocation, InnerDist, OuterDist);
		SetActorTickEnabled(true);




	}

	UFUNCTION(BlueprintEvent)
	void BP_BreakFloor()
	{

	}
}