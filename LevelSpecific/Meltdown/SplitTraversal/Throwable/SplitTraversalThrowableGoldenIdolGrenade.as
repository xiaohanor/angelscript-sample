class ASplitTraversalThrowableGoldenIdolGrenade : ASplitTraversalThrowable
{
	UPROPERTY(EditAnywhere)
	float BombTimer = 4.0;

	UPROPERTY()
	UNiagaraSystem ExplosionSystem;

	float ExplodeAtGameTimeSeconds;
	bool bExploded = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnThrowableCrossedSplitScreen.AddUFunction(this, n"HandleThrowableCrossedSplitScreen");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		Super::Tick(DeltaSeconds);
		
		if (Time::GameTimeSeconds > ExplodeAtGameTimeSeconds && bInScifi && !bExploded && !bIsThrowing && !bIsThrowInitiated)
			Explode();
	}

	UFUNCTION()
	private void HandleThrowableCrossedSplitScreen(bool bScifi)
	{
		if (bScifi)
		{
			bExploded = false;
			ExplodeAtGameTimeSeconds = Time::GameTimeSeconds + BombTimer;
		}

		else
		{

		}
		
	}

	void Explode()
	{
		bExploded = true;

		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, Game::Mio.ActorLocation);
		Niagara::SpawnOneShotNiagaraSystemAtLocation(ExplosionSystem, Game::Zoe.ActorLocation + 
													Game::Zoe.ViewRotation.RightVector * -600.0);

		for (auto Player : Game::GetPlayers())
			Player.KillPlayer();
	}
};