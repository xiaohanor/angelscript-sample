UCLASS(Abstract)
class AMeltdownBossPhaseThreeLaserCutterDestructionActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMeltdownShakeComponent Shake;

	UPROPERTY(DefaultComponent, Attach = Shake)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Shake)
	UStaticMeshComponent MeshTarget;

	UPROPERTY()
	UNiagaraSystem Explosion;

	UPROPERTY()
	FVector ImpactDirection;

	UPROPERTY()
	float ImpulseAmount;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void OnShakeDone()
	{
			Mesh.SetSimulatePhysics(true);
			FVector Impulse;

			if (ImpactDirection.Size() == 0)
				Impulse = ImpactDirection * ImpulseAmount;
			else
				Impulse = (Mesh.WorldLocation - ActorLocation).GetSafeNormal() * ImpulseAmount;

			Mesh.AddImpulse(Impulse);

			Niagara::SpawnOneShotNiagaraSystemAtLocation(Explosion,Mesh.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}
};
