class AIslandArenaRespawnPointsManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"IslandArenaRespawnPointsCapability");
#if EDITOR
	default CapabilityComp.DefaultCapabilities.Add(n"IslandArenaRespawnPointsDevTogglesCapability");
#endif

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Billboard;
	default Billboard.SpriteName = "Scenepoint";
	default Billboard.WorldScale3D = FVector(2.0); 
	default Billboard.RelativeLocation = FVector(0.0, 0.0, 100.0);

	UPROPERTY(DefaultComponent)
	UTextRenderComponent MarkerText;
	default MarkerText.IsVisualizationComponent = false;
	default MarkerText.Text = FText::FromString("RespawnPointsManager");
	default MarkerText.TextRenderColor = FColor::Silver;
	default MarkerText.RelativeLocation = FVector(0.0, 0.0, 200.0);
	default MarkerText.bHiddenInGame = true;
	default MarkerText.WorldSize = 75.0;
	default MarkerText.HorizontalAlignment = EHorizTextAligment::EHTA_Center;	
#endif	

	UPROPERTY(EditAnywhere)
	float RespawnSafeDistance = 500.0;

	// Points to pick from.
	UPROPERTY(EditInstanceOnly)
	TArray<ARespawnPoint> RespawnPoints;

	// Spawners relevant for this arena.
	UPROPERTY(EditInstanceOnly)
	TArray<AHazeActorSpawnerBase> Spawners;
	
	bool bIsActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AHazeActorSpawnerBase Spawner : Spawners)
		{
			Spawner.OnDepleted.AddUFunction(this, n"OnSpawnerDepleted");
		}
	}
	
	UFUNCTION()
	private void OnSpawnerDepleted(AHazeActor LastActor)
	{
		// Check if any spawner is still going.
		for (AHazeActorSpawnerBase Spawner : Spawners)
		{
			if (!Spawner.IsDepleted())
				return;
		}
		bIsActive = false;
	}

	UFUNCTION(BlueprintCallable)
	void Activate()
	{
		bIsActive = true;
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IslandArenaRespawnPointsManagerDevToggles::EnableDebugDrawing.IsEnabled())
			return;
		
		LastUsedTimer -= DeltaSeconds;

		for (ARespawnPoint RespawnPoint : RespawnPoints)
		{
			Debug::DrawDebugSphere(RespawnPoint.ActorLocation, 20, 12, FLinearColor::White);

			if (LastUsedTimer > 0.0 && RespawnPoint == LastUsedRespawnPoint)
				Debug::DrawDebugSphere(RespawnPoint.ActorLocation, RespawnSafeDistance, 12, FLinearColor::White);
			else
			{
				bool bIsBadPoint = false;
				for (AHazeActorSpawnerBase Spawner : Spawners)
				{
					UHazeTeam Team = Spawner.SpawnerComp.GetSpawnedActorsTeam();
					if (Team == nullptr)
						continue;
					TArray<AHazeActor> Members = Team.GetMembers();
					for(AHazeActor Member: Team.GetMembers())
					{
						if (Member.GetSquaredDistanceTo(RespawnPoint) < Math::Square(RespawnSafeDistance))
						{
							bIsBadPoint = true;
							break;
						}
					}
				}

				if (bIsBadPoint)
					Debug::DrawDebugSphere(RespawnPoint.ActorLocation, RespawnSafeDistance, 12, FLinearColor::Red);
				else
					Debug::DrawDebugSphere(RespawnPoint.ActorLocation, RespawnSafeDistance, 12, FLinearColor::Green);
			}
		}
	}

	float LastUsedTimer = 0.0;
	ARespawnPoint LastUsedRespawnPoint;

#endif
};

namespace IslandArenaRespawnPointsManagerDevToggles
{
	const FHazeDevToggleCategory ArenaRespawnPointsManagerCategory = FHazeDevToggleCategory(n"Arena RespawnPoints Manager");
	
	const FHazeDevToggleBool EnableDebugDrawing = FHazeDevToggleBool(ArenaRespawnPointsManagerCategory, n"Debug Drawing", n"Enable Debug drawing.");
}