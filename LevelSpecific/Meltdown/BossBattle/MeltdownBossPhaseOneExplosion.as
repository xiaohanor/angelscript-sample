class AMeltdownBossPhaseOneExplosion : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMeltdownBossCubeGridDisplacementComponent DisplacementComp;

	UPROPERTY(EditAnywhere)
	float FadeInDuration = 0.1;
	UPROPERTY(EditAnywhere)
	float Duration = 0.5;
	UPROPERTY(EditAnywhere)
	float FadeOutDuration = 0.2;

	UPROPERTY(EditAnywhere)
	float Radius = 100.0;
	UPROPERTY(EditAnywhere)
	FVector Displacement;

	UPROPERTY(EditAnywhere)
	bool bAutoDestroy = false;

	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		DisplacementComp.DeactivateDisplacement();
	}

	UFUNCTION()
	void ActivateExplosion()
	{
		RemoveActorDisable(this);
		DisplacementComp.ActivateDisplacement();

		Timer = 0.0;
		UpdateDisplacement();
	}

	void UpdateDisplacement()
	{
		DisplacementComp.Type = EMeltdownBossCubeGridDisplacementType::Shape;

		float Alpha = 1.0;
		if (Timer <= Duration)
			Alpha = Math::Saturate(Timer / FadeInDuration);
		else
			Alpha = 1.0 - ((Timer - Duration) / FadeOutDuration);

		DisplacementComp.Shape = FHazeShapeSettings::MakeSphere(Radius * 0.5);
		DisplacementComp.LerpDistance = Radius * 0.5;
		DisplacementComp.Displacement = Displacement * Alpha;
		DisplacementComp.bInfiniteHeight = true;
	}

	void CheckKillPlayers()
	{
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			FVector PlayerLocation = Player.ActorLocation;
			FVector DisplaceLocation = DisplacementComp.WorldLocation;

			float Distance = PlayerLocation.Distance(DisplaceLocation);
			if (Distance < Radius)
			{
				bool bPlayerIsAboveCubeGrid = false;
				
				TListedActors<AMeltdownBossCubeGrid> CubeGrids;
				for (AMeltdownBossCubeGrid Grid : CubeGrids)
				{
					if (Grid.IsLocationWithinGrid2D(Player.ActorLocation, 10.0))
						bPlayerIsAboveCubeGrid = true;
				}

				if (bPlayerIsAboveCubeGrid)
					Player.KillPlayer();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		UpdateDisplacement();
		CheckKillPlayers();

		if (Timer >= Duration + FadeOutDuration)
		{
			AddActorDisable(this);
			if (bAutoDestroy)
				DestroyActor();
		}
	}
};