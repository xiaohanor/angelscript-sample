delegate bool FBasicAIHealthBarVisiblityDelegate();

class UBasicAIHealthBarComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private FText BossHealthBarDesc;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private EHazeSelectPlayer PlayerVisibility = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private bool bEnabled = true;

	private TPerPlayer<UHealthBarWidget> HealthBars;
	private UBossHealthBarWidget BossHealthBar;
	private UBasicAIHealthComponent HealthComp;
	private UBasicAIHealthBarSettings Settings;

	// Bind a function to this delegate to override visibility
	FBasicAIHealthBarVisiblityDelegate ShouldShowHealthBarDelegate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnHealthChange.AddUFunction(this, n"UpdateHealth");
		Settings = UBasicAIHealthBarSettings::GetSettings(Cast<AHazeActor>(Owner));
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");			
		else 
			SetupHealthBars();
	}

	bool IsBossHealthBar()
	{
		return HealthBarWidgetClass.Get().IsChildOf(UBossHealthBarWidget);
	} 

	UFUNCTION()
	void UpdateHealth()
	{
		if (HealthComp.IsAlive())
		{
			UpdateHealthBarVisibility();
			for (AHazePlayerCharacter Player : Game::Players)
			{
				UpdateHealthBar(HealthBars[Player]);
			}
			UpdateHealthBar(BossHealthBar);
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

		if(BossHealthBar != nullptr)
			BossHealthBar.SnapHealthTo(HealthComp.CurrentHealth);
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

		switch (Settings.HealthBarVisibility) 
		{
			case EBasicAIHealthBarVisibility::AlwaysShow:
		 		return true;
		 	case EBasicAIHealthBarVisibility::OnlyShowWhenHurt:
		 		return (HealthComp.GetHealthFraction() < 1.0);
		}  
	}

	void SetupHealthBars()
	{
		if (HealthBarWidgetClass.IsValid())
		{
			RemoveHealthBars();
			UpdateHealthBarVisibility();
		}
	}

	void UpdateHealthBarVisibility()
	{
		if (!ShouldShowHealthBar() || !bEnabled)
		{
			RemoveHealthBars();
			return;
		}

		// Show health bars
		if (IsBossHealthBar())
		{
			// Show boss health bar
			if (BossHealthBar == nullptr)
			{
				BossHealthBar = Cast<UBossHealthBarWidget>(Widget::AddFullscreenWidget(HealthBarWidgetClass));
				BossHealthBar.InitBossHealthBar(BossHealthBarDesc, HealthComp.MaxHealth, Settings.HealthBarSegments);
			}

			// Remove player specific health bars
			for (AHazePlayerCharacter Player : Game::Players)
			{
				if (HealthBars[Player] != nullptr)
				{
					Player.RemoveWidget(HealthBars[Player]);
					HealthBars[Player] = nullptr;
				}
			}
		}
		else
		{
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

			// Remove boss health bar
			if (BossHealthBar != nullptr)
			{
				Widget::RemoveFullscreenWidget(BossHealthBar);
				BossHealthBar = nullptr;	
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

		if (BossHealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(BossHealthBar);
			BossHealthBar = nullptr;	
		}
	}

	UFUNCTION()
	void UpdateHealthBarSettings()
	{
		UpdateHealthBarVisibility();

		for (AHazePlayerCharacter Player : Game::GetPlayersSelectedBy(PlayerVisibility))
		{
			UpdateSingleHealthBarSettings(HealthBars[Player]);
		}

		if (BossHealthBar != nullptr)
			BossHealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
	}
	void UpdateSingleHealthBarSettings(UHealthBarWidget HealthBar)
	{	
		if (HealthBar == nullptr)
			return;

		USceneComponent AttachComp = USceneComponent::Get(Owner, Settings.HealthBarAttachComponentName);
		if (AttachComp == nullptr)
			AttachComp = Owner.RootComponent;

		HealthBar.AttachWidgetToComponent(AttachComp, Settings.HealthBarAttachSocket);
		HealthBar.SetWidgetRelativeAttachOffset(Settings.HealthBarOffset);
		HealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
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
	void OnActorDisabled()
	{
		RemoveHealthBars();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		SetupHealthBars();
		SnapBarToHealth();
	}
	
	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBars();
	}
}
