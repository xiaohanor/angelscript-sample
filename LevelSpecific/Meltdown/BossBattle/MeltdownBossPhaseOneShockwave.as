class AMeltdownBossPhaseOneShockwave : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMeltdownBossCubeGridDisplacementComponent DisplacementComp;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListComp;

	UPROPERTY(EditAnywhere)
	float Speed = 500.0;
	UPROPERTY(EditAnywhere)
	float InitialRadius = 0.0;
	UPROPERTY(EditAnywhere)
	float MaxRadius = 2000.0;
	UPROPERTY(EditAnywhere)
	FVector Displacement;

	UPROPERTY(EditAnywhere)
	float Width = 0.0;

	UPROPERTY(EditAnywhere)
	bool bAutoDestroy = true;

	float Timer = 0.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);
		DisplacementComp.DeactivateDisplacement();
		
		// This class has no BP, so get the sound def class from Rader himself
		auto Rader = ActorList::GetSingle(AMeltdownBossPhaseOne);
		FSoundDefReference(Rader.ShockwaveSoundDef).SpawnSoundDefAttached(this);
	}

	UFUNCTION()
	void ActivateShockwave()
	{
		RemoveActorDisable(this);
		DisplacementComp.ActivateDisplacement();

		Timer = 0.0;
		UpdateDisplacement();
	}

	void UpdateDisplacement()
	{
		DisplacementComp.Type = EMeltdownBossCubeGridDisplacementType::Circle;
		DisplacementComp.CircleRadius = Math::Min(MaxRadius, InitialRadius + Speed * Timer);
		DisplacementComp.LerpDistance = Width;
		DisplacementComp.Displacement = Displacement;
	}

	void CheckKillPlayers()
	{
		for (auto Player : Game::Players)
		{
			if (Player.IsPlayerDead())
				continue;

			FVector PlayerLocation = Player.ActorLocation;
			FVector ShockwaveLocation = DisplacementComp.WorldLocation;

			float FlatDistance = PlayerLocation.Dist2D(ShockwaveLocation) - DisplacementComp.CircleRadius;
			if (Math::Abs(FlatDistance) < Width)
			{
				bool bGrounded = UPlayerMovementComponent::Get(Player).IsOnAnyGround();
				if (bGrounded)
				{
					bool bPlayerIsAboveCubeGrid = false;
					
					TListedActors<AMeltdownBossCubeGrid> CubeGrids;
					for (AMeltdownBossCubeGrid Grid : CubeGrids)
					{
						if (Grid.IsLocationWithinGrid2D(Player.ActorLocation, Width))
							bPlayerIsAboveCubeGrid = true;
					}

					if (bPlayerIsAboveCubeGrid && !Player.IsPlayerInvulnerable())
					{
						FVector KnockDirection = (Player.ActorLocation - ShockwaveLocation).GetSafeNormal2D();
						Player.AddKnockbackImpulse(KnockDirection, 1200.0, 1200.0);
						Player.DamagePlayerHealth(0.5);
					}
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Timer += DeltaSeconds;

		UpdateDisplacement();
		CheckKillPlayers();

		if (Timer >= (MaxRadius - InitialRadius) / Speed)
		{
			AddActorDisable(this);
			if (bAutoDestroy)
				DestroyActor();
		}
	}
};