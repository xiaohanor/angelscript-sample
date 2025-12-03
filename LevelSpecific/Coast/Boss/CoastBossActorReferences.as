event void FCoastBossActorReferencesMoveToPortalEvent();

class ACoastBossActorReferences : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditInstanceOnly)
	ASplineFollowCameraActor Camera;

	UPROPERTY(EditInstanceOnly)
	ASplineFollowCameraActor EnterCamera;

	UPROPERTY(EditInstanceOnly)
	ASplineFollowCameraActor ExitCamera;

	UPROPERTY(EditInstanceOnly)
	ACoastBoss2DPlane CoastBossPlane2D;

	UPROPERTY(EditInstanceOnly)
	ACoastBoss Boss;

	UPROPERTY(EditInstanceOnly)
	ARespawnPoint PlaneRespawnPoint;

	UPROPERTY(EditInstanceOnly)
	ACoastBossDrillbazzTelegraph DrillbazzTelegraph;

	UPROPERTY(EditInstanceOnly)
	TMap<ECoastBossPlayerPowerUpType, TSubclassOf<ACoastBossPlayerNormalPowerUp>> PowerUpClasses;

	UPROPERTY(EditInstanceOnly)
	TArray<ECoastBossPlayerPowerUpType> PowerUpOrder;

	UPROPERTY()
	FCoastBossActorReferencesMoveToPortalEvent OnMoveToPortal;

	private ACoastBossPlayerDrone Internal_MioDrone;
	private ACoastBossPlayerDrone Internal_ZoeDrone;
	TArray<ACoastBossPlayerNormalPowerUp> PowerUps;
	int PowerUpIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(int i = 0; i < PowerUpOrder.Num(); i++)
		{
			ECoastBossPlayerPowerUpType Type = PowerUpOrder[i];
			ACoastBossPlayerNormalPowerUp PowerUp = SpawnActor(PowerUpClasses[Type], bDeferredSpawn = true);
			PowerUp.PowerUpType = Type;
			PowerUp.MakeNetworked(this, n"_PowerUp", i);
			FinishSpawningActor(PowerUp);
			PowerUps.Add(PowerUp);
		}
	}

	void TrySpawnPowerup(float SinusOffset, float XOffset)
	{
		if (!HasControl())
			return;

		if (PowerUps[PowerUpIndex].bActive)
			return;

		if (PowerUps[PowerUpIndex].bPendingActive)
			return;

		PowerUps[PowerUpIndex].Activate(SinusOffset, XOffset);
		PowerUpIndex++;
		PowerUpIndex = Math::WrapIndex(PowerUpIndex, 0, PowerUps.Num());
	}

	ACoastBossPlayerDrone GetMioDrone() property
	{
		if(Internal_MioDrone != nullptr)
			return Internal_MioDrone;

		for(auto Drone : TListedActors<ACoastBossPlayerDrone>().Array)
		{
			if(Drone.User == EHazePlayer::Mio)
			{
				Internal_MioDrone = Drone;
				break;
			}
		}

		return Internal_MioDrone;
	}

	ACoastBossPlayerDrone GetZoeDrone() property
	{
		if(Internal_ZoeDrone != nullptr)
			return Internal_ZoeDrone;

		for(auto Drone : TListedActors<ACoastBossPlayerDrone>().Array)
		{
			if(Drone.User == EHazePlayer::Zoe)
			{
				Internal_ZoeDrone = Drone;
				break;
			}
		}

		return Internal_ZoeDrone;
	}
};