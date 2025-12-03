delegate bool FIslandOverseerEyeHealthBarVisiblityDelegate();

class UIslandOverseerEyeHealthBarComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private EHazeSelectPlayer PlayerVisibility = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private bool bEnabled = true;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	FVector Offset;

	private TPerPlayer<UHealthBarWidget> HealthBars;

#if EDITOR
	private FTimerHandle EditorUpdateHandle;
#endif

	UBasicAIHealthComponent HealthComp;

	// Bind a function to this delegate to override visibility
	FBasicAIHealthBarVisiblityDelegate ShouldShowHealthBarDelegate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
	}

	void Initialize()
	{
		SetupHealthBars();
	}

	UFUNCTION()
	void OnTakeDamage(AHazeActor Actor, AHazeActor Instigator, float Damage, EDamageType DamageType)
	{
		if (Actor != Owner)
			return;

		if (HealthComp.IsAlive())
		{
			UpdateHealthBarVisibility();
			for (AHazePlayerCharacter Player : Game::Players)
			{
				UpdateHealthBar(HealthBars[Player]);
			}
		}
		else // Dead
		{
			RemoveHealthBars();
		}
	}

	void SnapBarToHealth()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (HealthBars[Player] != nullptr)
			{
				HealthBars[Player].SnapHealthTo(HealthComp.CurrentHealth);
			}
		}
	}

	protected bool ShouldShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return false;

		if (HealthComp.MaxHealth < SMALL_NUMBER)
		 	return false;

		if (ShouldShowHealthBarDelegate.IsBound())
		{
			if (!ShouldShowHealthBarDelegate.Execute())
				return false;
		}

		return true;
	}

	void SetupHealthBars()
	{
		if (HealthBarWidgetClass.IsValid())
		{
			RemoveHealthBars();
			UpdateHealthBarVisibility();
#if EDITOR
			EditorUpdateHandle = Timer::SetTimer(this, n"UpdateHealthBarSettings", 1.0, true);
#endif
		}
	}

	void UpdateHealthBarVisibility()
	{
		if (!ShouldShowHealthBar() || !bEnabled)
		{
			RemoveHealthBars();
			return;
		}

		// Player health bars
		for (AHazePlayerCharacter Player : Game::Players)
		{
			// Show if selected
			if (HealthBars[Player] == nullptr && Player.IsSelectedBy(PlayerVisibility))
			{
				HealthBars[Player] = AddHealthBarWidget(Player);
				UpdateSingleHealthBarSettings(HealthBars[Player]);
			}
			// Remove if not selected
			else if (HealthBars[Player] != nullptr && !Player.IsSelectedBy(PlayerVisibility))
			{
				Player.RemoveWidget(HealthBars[Player]);
				HealthBars[Player] = nullptr;
			}
		}
	}

	private UHealthBarWidget AddHealthBarWidget(AHazePlayerCharacter Player)
	{
		if (!HealthBarWidgetClass.IsValid())
			return nullptr;

		UHealthBarWidget HealthBar = Player.AddWidget(HealthBarWidgetClass);
		HealthBar.InitHealthBar(HealthComp.MaxHealth);
		return HealthBar;
	}

	private void UpdateHealthBar(UHealthBarWidget HealthBar)
	{
		if (HealthBar == nullptr)
			return;
		HealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
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
#if EDITOR
		if (EditorUpdateHandle.IsValid())
			EditorUpdateHandle.ClearTimerAndInvalidateHandle();
#endif
	}

	UFUNCTION()
	void UpdateHealthBarSettings()
	{
		UpdateHealthBarVisibility();

		for (AHazePlayerCharacter Player : Game::GetPlayersSelectedBy(PlayerVisibility))
		{
			UpdateSingleHealthBarSettings(HealthBars[Player]);
		}
	}
	void UpdateSingleHealthBarSettings(UHealthBarWidget HealthBar)
	{	
		if (HealthBar == nullptr)
			return;

		HealthBar.AttachWidgetToComponent(Owner.RootComponent);
		HealthBar.SetWidgetRelativeAttachOffset(Offset);
		HealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
		HealthBar.SetBarSize(EHealthBarSize::Big);
	}

	UFUNCTION()
	void SetPlayerVisibility(EHazeSelectPlayer NewPlayerVisibility)
	{
		PlayerVisibility = NewPlayerVisibility;
		if (HasBegunPlay())
			UpdateHealthBarVisibility();
	}

	UFUNCTION()
	void SetHealthBarEnabled(bool bValue)
	{
		bEnabled = bValue;
		if (HasBegunPlay())
			UpdateHealthBarVisibility();
	}

	UFUNCTION()
	private void OnRespawn()
	{
		SetupHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SetupHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		RemoveHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBars();
	}
}
