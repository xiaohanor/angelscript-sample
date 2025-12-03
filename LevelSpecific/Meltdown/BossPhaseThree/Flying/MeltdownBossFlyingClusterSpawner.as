event void FOnSpawningDone();

class AMeltdownBossFlyingClusterSpawner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Sphere;

	UPROPERTY(EditAnywhere)
	float SpawnInterval;

	UPROPERTY()
	int AmountSpawned;

	UPROPERTY(EditAnywhere)
	int NumberToSpawn;

	UPROPERTY()
	int GroupsToSpawn;

	UPROPERTY()
	FOnSpawningDone SpawningDone;

	FVector StartScale = FVector(0.1,0.1,0.1);
	FVector EndScale = FVector(8.0,8.0,8.0);

	FHazeTimeLike OpenPortal;
	default OpenPortal.Duration = 1.0;
	default OpenPortal.UseSmoothCurveZeroToOne();

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		OpenPortal.BindFinished(this, n"PortalOpen");
		OpenPortal.BindUpdate(this, n"PortalOpening");
	}

	UFUNCTION()
	private void PortalOpening(float CurrentValue)
	{
		Sphere.SetRelativeScale3D(Math::Lerp(StartScale, EndScale, CurrentValue));
	}

	UFUNCTION()
	private void PortalOpen()
	{
		if(OpenPortal.IsReversed())
		{
			SpawningDone.Broadcast();
			AddActorDisable(this);
			return;
		}
		
		Spawning();
	}

	UFUNCTION(BlueprintCallable)
	void Launch()
	{
		RemoveActorDisable(this);
		OpenPortal.PlayFromStart();
	}

	UFUNCTION(BlueprintEvent)
	void Spawning()
	{
	}

	UFUNCTION(BlueprintCallable)
	void DoneSpawning()
	{
		OpenPortal.ReverseFromEnd();
	}
};