event void FTundraRiverAvalancheRespawnEvent(ATundra_River_AvalancheRespawnPoint RespawnPoint, AHazePlayerCharacter Player);

class ATundra_River_AvalancheRespawnPoint : ARespawnPoint
{
	FTundraRiverAvalancheRespawnEvent OnAvalancheRespawnPointEnabled;
	FTundraRiverAvalancheRespawnEvent OnAvalancheRespawnPointDisabled;

	void OnEnabledForPlayer(AHazePlayerCharacter Player) override
	{
		Super::OnEnabledForPlayer(Player);
		OnAvalancheRespawnPointEnabled.Broadcast(this, Player);
	}

	void OnDisabledForPlayer(AHazePlayerCharacter Player) override
	{
		Super::OnDisabledForPlayer(Player);
		OnAvalancheRespawnPointDisabled.Broadcast(this, Player);
	}
}

class ATundra_River_AvalancheRespawnSystem : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach=Root)
	UEditorBillboardComponent Billboard;
	default Billboard.SetSpriteName("S_Player");
#endif

	UPROPERTY(DefaultComponent)
	UTundra_River_AvalancheRespawnSystem_VisualizerDummyComponent VisualizerDummyComp;

	UPROPERTY(EditAnywhere)
	TArray<ATundra_River_AvalancheRespawnPoint> RespawnPoints;

	// Set to true if you want the respawn system to be active from the start of the game, otherwise manually enable it with EnableRespawnSystem()
	UPROPERTY(EditAnywhere, BlueprintHidden)
	bool bEnabled = false;

	private TArray<ATundra_River_AvalancheRespawnPoint> EnabledRespawnPoints;
	private bool bRespawnBlocked = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(ATundra_River_AvalancheRespawnPoint RespawnPoint : RespawnPoints)
		{
			if(RespawnPoint.IsEnabledForPlayer(Game::Mio))
				EnabledRespawnPoints.AddUnique(RespawnPoint);

			RespawnPoint.OnAvalancheRespawnPointEnabled.AddUFunction(this, n"OnRespawnPointEnabled");
			RespawnPoint.OnAvalancheRespawnPointDisabled.AddUFunction(this, n"OnRespawnPointDisabled");
		}

		CheckBlockRespawn();
	}

	UFUNCTION()
	private void OnRespawnPointEnabled(ATundra_River_AvalancheRespawnPoint RespawnPoint, AHazePlayerCharacter EnablingPlayer)
	{
		EnabledRespawnPoints.AddUnique(RespawnPoint);
		CheckUnblockRespawn();
	}

	UFUNCTION()
	private void OnRespawnPointDisabled(ATundra_River_AvalancheRespawnPoint RespawnPoint, AHazePlayerCharacter DisablingPlayer)
	{
		EnabledRespawnPoints.Remove(RespawnPoint);
		CheckBlockRespawn();
	}

	UFUNCTION()
	void EnableRespawnSystem()
	{
		devCheck(!bEnabled, "Cannot enable respawn system since it is already enabled");
		bEnabled = true;
		CheckBlockRespawn();
	}

	UFUNCTION()
	void DisableRespawnSystem()
	{
		devCheck(bEnabled, "Cannot disable respawn system since it is already disabled");
		bEnabled = false;
		CheckUnblockRespawn();
	}

	UFUNCTION(BlueprintPure)
	bool IsRespawnSystemEnabled()
	{
		return bEnabled;
	}

	private void CheckBlockRespawn()
	{
		if(!bEnabled)
			return;

		if(bRespawnBlocked)
			return;

		if(EnabledRespawnPoints.Num() > 0)
			return;

		Game::Mio.BlockCapabilities(n"Respawn", this);
		Game::Zoe.BlockCapabilities(n"Respawn", this);
		bRespawnBlocked = true;
	}

	private void CheckUnblockRespawn()
	{
		if(!bRespawnBlocked)
			return;

		if(EnabledRespawnPoints.Num() == 0)
			return;

		Game::Mio.UnblockCapabilities(n"Respawn", this);
		Game::Zoe.UnblockCapabilities(n"Respawn", this);
		bRespawnBlocked = false;
	}
}

UCLASS(NotPlaceable)
class UTundra_River_AvalancheRespawnSystem_VisualizerDummyComponent : UActorComponent
{
	default bIsEditorOnly = true;
}

class UTundra_River_AvalancheRespawnSystem_Visualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UTundra_River_AvalancheRespawnSystem_VisualizerDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto System = Cast<ATundra_River_AvalancheRespawnSystem>(Component.Owner);
		devCheck(System != nullptr, "Visualizer for avalanche respawn system is trying to visualize something else.");

		for(ATundra_River_AvalancheRespawnPoint Point : System.RespawnPoints)
		{
			if(Point == nullptr)
				continue;

			DrawLine(System.ActorLocation, Point.ActorLocation, FLinearColor::Red, 3.0);
		}
	}
}