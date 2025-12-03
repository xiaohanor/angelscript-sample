UCLASS(Abstract)
class AIslandEntranceRandomExplosions : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent BillboardComp;

	UPROPERTY(EditAnywhere)
	UNiagaraSystem ExplosionEfect;

	UPROPERTY(EditAnywhere)
	float MinRandomTime = 1;
	
	UPROPERTY(EditAnywhere)
	float MaxRandomTime = 5;

	UPROPERTY(EditAnywhere)
	float Radius = 500;

	float CurrentTime = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CurrentTime = GetRandomTime();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(CurrentTime > 0)
		{
			CurrentTime -= DeltaSeconds;
		}
		else
		{
			SpawnEffect();
		}
	}

	float GetRandomTime()
	{
		return Math::RandRange(MinRandomTime, MaxRandomTime);
	}

	void SpawnEffect()
	{
		FVector Location = Math::GetRandomPointInSphere() * Radius;
		UNiagaraComponent SpawnedEffect = Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionEfect, ActorLocation + Location);
		CurrentTime = GetRandomTime();
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSphere(ActorLocation, Radius, Thickness = 24);
	}
#endif
};

