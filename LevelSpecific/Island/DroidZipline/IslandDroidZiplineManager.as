UCLASS(Abstract)
class AIslandDroidZiplineManager : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeRequestCapabilityOnPlayerComponent CapabilityRequestComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere)
	float SpawnCooldown = 2.0;

	UPROPERTY(EditAnywhere)
	bool bShouldSpawn = true;

	UPROPERTY(EditAnywhere)
	TSubclassOf<AIslandDroidZipline> DroidClass;

	UPROPERTY(EditInstanceOnly)
	TArray<AIslandDroidZiplinePatrolSpline> PatrolSplines;

	UPROPERTY(EditInstanceOnly)
	AIslandDroidZiplineZiplineSpline ZiplineSpline;

	private float LastSpawnedTime = -1.0;
	private UHazeActorNetworkedSpawnPoolComponent SpawnPool;
	private int NextDroidSplineIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnPool = HazeActorNetworkedSpawnPoolStatics::GetOrCreateSpawnPool(DroidClass, this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!HasControl())
			return;

		const float Time = Time::GetGameTimeSeconds();
		if(bShouldSpawn && (LastSpawnedTime < 0.0 || Time - LastSpawnedTime > SpawnCooldown))
		{
			SpawnDroid();
		}
	}

	private void SpawnDroid()
	{
		AIslandDroidZiplinePatrolSpline PatrolSpline = PatrolSplines[NextDroidSplineIndex];
		++NextDroidSplineIndex;
		NextDroidSplineIndex %= PatrolSplines.Num();
		FTransform BeginningTransform = PatrolSpline.Spline.GetWorldTransformAtSplineDistance(0.0);

		FHazeActorSpawnParameters Params;
		Params.Location = BeginningTransform.Location;
		Params.Rotation = BeginningTransform.Rotator();
		Params.Spawner = this;
		auto Droid = Cast<AIslandDroidZipline>(SpawnPool.SpawnControl(Params));
		NetDroidSpawned(Droid, PatrolSpline);
		LastSpawnedTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(NetFunction)
	private void NetDroidSpawned(AIslandDroidZipline Droid, AIslandDroidZiplinePatrolSpline PatrolSpline)
	{
		Droid.OnSpawnDroid(PatrolSpline, ZiplineSpline, SpawnPool, this);
	}

	UFUNCTION(BlueprintCallable)
	void SetShouldSpawn(bool bEnable)
	{
		bShouldSpawn = bEnable;
	}
}