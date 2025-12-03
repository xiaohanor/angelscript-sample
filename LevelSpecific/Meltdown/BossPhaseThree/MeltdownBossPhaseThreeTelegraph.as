class AMeltdownBossPhaseThreeTelegraph : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UTelegraphDecalComponent Telegraph;

	AMeltdownBossPhaseThreeRainAttack Hydra;

	float RemainingDuration = 0.0;
	bool bHiddenTelegraph = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	void HideAndDestroy()
	{
		RemainingDuration = 0.5;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (RemainingDuration >= 0)
		{
			RemainingDuration -= DeltaSeconds;
			if (RemainingDuration <= 0.5 && !bHiddenTelegraph)
			{
				Telegraph.HideTelegraph();
				bHiddenTelegraph = true;
			}

			if (RemainingDuration <= 0.0)
				DestroyActor();
		}
	}
};

namespace MeltdownBossPhaseThree
{
	AMeltdownBossPhaseThreeTelegraph SpawnTelegraph(TSubclassOf<AMeltdownBossPhaseThreeTelegraph> Class, FVector Location, float Radius, float Duration = -1.0, ETelegraphDecalType Type = ETelegraphDecalType::Fantasy)
	{
		AMeltdownBossPhaseThreeTelegraph Telegraph = SpawnActor(Class, Location);
		Telegraph.RemainingDuration = Duration;
		Telegraph.Telegraph.SetRadius(Radius);
		Telegraph.Telegraph.SetTelegraphType(Type);
		return Telegraph;
	}
}