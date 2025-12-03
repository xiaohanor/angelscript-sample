UCLASS(HideCategories = "Collision BrushSettings Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass)
class ARedSpaceTetherRespawnPointVolume : APlayerTrigger
{
	default Shape::SetVolumeBrushColor(this, FLinearColor(1.00, 0.5, 0.00));
	default BrushComponent.LineThickness = 3.0;

	UPROPERTY(EditAnywhere)
	ARespawnPoint RespawnPoint;

	bool bTriggeredByMio = false;
	bool bTriggeredByZoe = false;

	bool bActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnPlayerEnter.AddUFunction(this, n"EnterTrigger");

		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			UPlayerHealthComponent HealthComp = UPlayerHealthComponent::Get(Player);
			HealthComp.OnDeathTriggered.AddUFunction(this, n"PlayerDied");
		}
	}

	UFUNCTION()
	private void PlayerDied()
	{
		if (bActivated)
			return;

		bTriggeredByMio = false;
		bTriggeredByZoe = false;
	}

	UFUNCTION()
	private void EnterTrigger(AHazePlayerCharacter Player)
	{
		if (Player.IsMio())
		{
			if (bTriggeredByMio)
				return;

			bTriggeredByMio = true;
		}

		if (Player.IsZoe())
		{
			if (bTriggeredByZoe)
				return;

			bTriggeredByZoe = true;
		}

		if (bTriggeredByMio && bTriggeredByZoe && !bActivated)
		{
			bActivated = true;
			for (AHazePlayerCharacter _Player : Game::GetPlayers())
				_Player.SetStickyRespawnPoint(RespawnPoint);
		}
	}
}