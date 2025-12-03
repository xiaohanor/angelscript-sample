class UHealthBarInWorldComponent : USceneComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private EHazeSelectPlayer PlayerVisibility = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private bool bOnlyShowWhenHurt = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Health")
	float MaxHealth = 1.0;
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Health")
	float CurrentHealth = 1.0;

	private TPerPlayer<UHealthBarWidget> HealthBars;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetupHealthBars();
	}

	protected bool ShouldShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return false;

		if (MaxHealth < SMALL_NUMBER)
		 	return false;

		if (bOnlyShowWhenHurt && CurrentHealth >= MaxHealth)
			return false;

		return true;
	}

	void SetupHealthBars()
	{
		UpdateHealthBars();
	}

	void UpdateHealthBars()
	{
		if (!ShouldShowHealthBar() || !bEnabled)
		{
			RemoveHealthBars();
			return;
		}

		// Show health bars
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Show if selected
			if (HealthBars[Player] == nullptr && Player.IsSelectedBy(PlayerVisibility))
			{
				HealthBars[Player] = AddHealthBarWidget(Player);
				HealthBars[Player].AttachWidgetToComponent(this);
				UpdateHealthBar(HealthBars[Player]);
			}
			// Remove if not selected
			else if (HealthBars[Player] != nullptr)
			{
				if (!Player.IsSelectedBy(PlayerVisibility))
				{
					Player.RemoveWidget(HealthBars[Player]);
					HealthBars[Player] = nullptr;
				}
				else
				{
					UpdateHealthBar(HealthBars[Player]);
				}
			}
		}
	}

	private UHealthBarWidget AddHealthBarWidget(AHazePlayerCharacter Player)
	{
		if (!HealthBarWidgetClass.IsValid())
			return nullptr;

		UHealthBarWidget HealthBar = Player.AddWidget(HealthBarWidgetClass);
		HealthBar.InitHealthBar(MaxHealth);
		return HealthBar;
	}

	private void UpdateHealthBar(UHealthBarWidget HealthBar)
	{
		if (HealthBar == nullptr)
			return;
		HealthBar.MaxHealth = MaxHealth;
		HealthBar.SetHealthAsDamage(CurrentHealth);
	}

	void RemoveHealthBars()
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

	void SetHealthBarEnabled(bool bValue)
	{
		bEnabled = bValue;
		if (HasBegunPlay())
			UpdateHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		RemoveHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SetupHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UpdateHealthBars();
	}
}
