class UDentistBossArmWeakpointHealthBarComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Setup")
	private TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	private TPerPlayer<UHealthBarWidget> HealthBars;

	float Health = 1.0;

	void Initialize()
	{
		Health = 1.0;
	}

	void ModifyHealth(float RemainingHealth)
	{
		Health = RemainingHealth;
		if(Health < 1.0)
			ShowHealthBar();
		else
			HideHealthBar();
			
		UpdateHealthBar();
	}

	void ShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return;
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
				continue;
			HealthBars[Player] = Player.AddWidget(HealthBarWidgetClass);
			HealthBars[Player].InitHealthBar(1.0);
			HealthBars[Player].AttachWidgetToComponent(this, NAME_None);
		}
	}

	void UpdateHealthBar()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
				HealthBars[Player].SetHealthAsDamage(Health);
		}
	}

	void HideHealthBar()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
			{
				Player.RemoveWidget(HealthBars[Player]);
				HealthBars[Player] = nullptr;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		HideHealthBar();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		HideHealthBar();
	}
}