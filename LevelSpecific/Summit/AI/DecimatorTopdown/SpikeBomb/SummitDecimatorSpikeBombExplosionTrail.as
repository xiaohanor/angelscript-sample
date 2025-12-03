// Spawned by SpikeBombs
UCLASS(Abstract)
class ASummitDecimatorSpikeBombExplosionTrail : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(EditAnywhere, DefaultComponent)
	UNiagaraComponent VFX;

	//UHazeActorLocalSpawnPoolComponent ExplosionTrailSpawnPool;

	private float TimeToLiveTimer;
	private float ScaleDiminishFactor = 0.25;

	private float OriginalScale;	
	private float Scale;

	private bool bIsActive = false;

	void Setup(USummitDecimatorSpikeBombSettings Settings)
	{
		TimeToLiveTimer = Settings.ExplosionTrailTimeToLive;
		ScaleDiminishFactor = Settings.ExplosionTrailScaleDiminishFactor;
		Scale = OriginalScale;		
		bIsActive = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OriginalScale = Mesh.WorldScale.X;
		Scale = OriginalScale;
		bIsActive = true;
		//ExplosionTrailSpawnPool = DecimatorTopdown::Spikebomb::GetSpikebombExplosionTrailSpawnPool();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{		
		if (!bIsActive)
			return;
		
		//ExplosionTrailSpawnPool.UnSpawn(this);
	}


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if (!bIsActive)
			return;

		Scale -= DeltaSeconds * Scale * ScaleDiminishFactor;
		Scale = Math::Clamp(Scale, 0, OriginalScale);
		TimeToLiveTimer -= DeltaSeconds;

		if (TimeToLiveTimer < 0)
		{
			// Return to spawnpool
			//ExplosionTrailSpawnPool.UnSpawn(this);
			bIsActive = false;
		}
		Mesh.SetWorldScale3D(FVector(Scale,Scale,Scale));
	}

}