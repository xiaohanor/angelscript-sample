UCLASS(Abstract)
class AMotherKiteClusterManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<AMotherKiteCluster> ClusterClass;

	UPROPERTY(EditInstanceOnly)
	ASplineActor SpawnSpline;
	UHazeSplineComponent SplineComp;

	AMotherKite MotherKite;

	bool bActive = false;

	float SpawnFwdOffset = 80000.0;
	float SpawnMaxSideOffset = 1600.0;
	float DespawnOffset = 5000.0;

	float MinSpawnInterval = 1.5;
	float MaxSpawnInterval = 2.0;
	float CurrentSpawnInterval = 0.0;
	float TimeUntilSpawn = 0.0;

	TArray<AMotherKiteCluster> ActiveClusters;

	int NetworkdId = 0;

	int SideIndex = 0;
	TArray<float> SideOffsets;
	default SideOffsets.Add(0.0);
	default SideOffsets.Add(-400.0);
	default SideOffsets.Add(1400.0);
	default SideOffsets.Add(-1400.0);
	default SideOffsets.Add(400.0);
	default SideOffsets.Add(-1000.0);
	default SideOffsets.Add(-100.0);
	default SideOffsets.Add(1600.0);
	default SideOffsets.Add(-1200.0);
	default SideOffsets.Add(-200.0);
	default SideOffsets.Add(1600.0);
	default SideOffsets.Add(200.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MotherKite = TListedActors<AMotherKite>().Single;

		SplineComp = SpawnSpline.Spline;
	}

	UFUNCTION()
	void Activate()
	{
		if (!HasControl())
			return;

		TimeUntilSpawn = Math::RandRange(MinSpawnInterval, MaxSpawnInterval);
		bActive = true;
	}

	UFUNCTION()
	void SpawnKiteCluster()
	{
		if (!HasControl())
			return;

		float MotherKiteSplineDist = SpawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(MotherKite.ActorLocation);
		float SpawnDist = Math::Wrap(MotherKiteSplineDist + SpawnFwdOffset, 0.0, SplineComp.SplineLength);

		FVector SpawnLoc = SplineComp.GetWorldLocationAtSplineDistance(SpawnDist);
		float SpawnSideOffset = SideOffsets[SideIndex];
		SpawnLoc += SplineComp.GetWorldRotationAtSplineDistance(SpawnDist).RightVector * SpawnSideOffset;

		TimeUntilSpawn = Math::RandRange(MinSpawnInterval, MaxSpawnInterval);

		NetSpawnKiteCluster(SpawnLoc);

		if (SideIndex >= SideOffsets.Num() - 1)
			SideIndex = 0;
		else
			SideIndex++;
	}

	UFUNCTION(NetFunction)
	void NetSpawnKiteCluster(FVector SpawnLoc)
	{
		AMotherKiteCluster Cluster = Cast<AMotherKiteCluster>(SpawnActor(ClusterClass, SpawnLoc, bDeferredSpawn = true));
		Cluster.MakeNetworked(NetworkdId);
		FinishSpawningActor(Cluster);
		NetworkdId++;

		if (HasControl())
			ActiveClusters.Add(Cluster);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		TimeUntilSpawn -= DeltaTime;
		if (TimeUntilSpawn <= 0.0)
		{
			SpawnKiteCluster();
		}

		float MotherKiteSplineDist = SpawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(MotherKite.ActorLocation);

		for (AMotherKiteCluster Cluster : ActiveClusters)
		{
			
		}
	}

	UFUNCTION()
	void SpawnInitialClusters(AActor RefActor)
	{
		if (!HasControl())
			return;

		float MotherKiteSplineDist = SpawnSpline.Spline.GetClosestSplineDistanceToWorldLocation(RefActor.ActorLocation);

		for (int i = 0; i <= 20; i++)
		{
			float SpawnDist = Math::Wrap(MotherKiteSplineDist + (2000.0 + (4000.0 * i)), 0.0, SplineComp.SplineLength);

			FVector SpawnLoc = SplineComp.GetWorldLocationAtSplineDistance(SpawnDist);
			float SpawnSideOffset = SideOffsets[SideIndex];
			SpawnLoc += SplineComp.GetWorldRotationAtSplineDistance(SpawnDist).RightVector * SpawnSideOffset;
			NetSpawnKiteCluster(SpawnLoc);

			if (SideIndex >= SideOffsets.Num() - 1)
				SideIndex = 0;
			else
				SideIndex++;
		}
	}
}