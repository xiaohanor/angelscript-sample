/*
 * Ugly Actor just to allow binding PrisonStealthManager events in the level BP
*/
class APrisonStealthLevelEvents : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY()
	FStealthPlayerDetectedEvent OnStealthPlayerDetected;

	UPROPERTY()
	FStealthPlayerEnterVisionEvent OnStealthPlayerEnterVision;

	UPROPERTY()
	FStealthPlayerExitVisionEvent OnStealthPlayerExitVision;

	UPROPERTY()
	FStealthAnyPlayerDetectedEvent OnStealthAnyPlayerDetected;

	UPROPERTY()
	FStealthFirstPlayerEnterVisionEvent OnStealthFirstPlayerEnterVision;

	UPROPERTY()
	FStealthAllPlayersExitVisionEvent OnStealthAllPlayersExitVision;

	UPROPERTY()
	FOnPlayerRespawned OnStealthPlayerRespawned;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto RespawnComp = UPlayerRespawnComponent::Get(Game::Mio);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");

		RespawnComp = UPlayerRespawnComponent::Get(Game::Zoe);
		RespawnComp.OnPlayerRespawned.AddUFunction(this, n"OnPlayerRespawned");

		PrisonStealth::GetStealthManager().OnStealthPlayerDetected.AddUFunction(this, n"OnPlayerDetected");
		PrisonStealth::GetStealthManager().OnStealthPlayerEnterVision.AddUFunction(this, n"OnPlayerEnterVision");
		PrisonStealth::GetStealthManager().OnStealthPlayerExitVision.AddUFunction(this, n"OnPlayerExitVision");

		PrisonStealth::GetStealthManager().OnStealthAnyPlayerDetected.AddUFunction(this, n"OnAnyPlayerDetected");
		PrisonStealth::GetStealthManager().OnStealthFirstPlayerEnterVision.AddUFunction(this, n"OnFirstPlayerEnterVision");
		PrisonStealth::GetStealthManager().OnStealthAllPlayersExitVision.AddUFunction(this, n"OnAllPlayersExitVision");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerRespawned(AHazePlayerCharacter RespawnedPlayer)
	{
		OnStealthPlayerRespawned.Broadcast(RespawnedPlayer);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerDetected(APrisonStealthEnemy DetectedBy, AHazePlayerCharacter DetectedPlayer)
	{
		OnStealthPlayerDetected.Broadcast(DetectedBy, DetectedPlayer);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerEnterVision(AHazePlayerCharacter Player)
	{
		OnStealthPlayerEnterVision.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnPlayerExitVision(AHazePlayerCharacter Player)
	{
		OnStealthPlayerExitVision.Broadcast(Player);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAnyPlayerDetected()
	{
		OnStealthAnyPlayerDetected.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnFirstPlayerEnterVision()
	{
		OnStealthFirstPlayerEnterVision.Broadcast();
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnAllPlayersExitVision()
	{
		OnStealthAllPlayersExitVision.Broadcast();
	}
};