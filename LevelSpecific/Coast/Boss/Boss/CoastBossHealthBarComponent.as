class UCoastBossHealthBarComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private FText BossHealthBarDesc;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private EHazeSelectPlayer PlayerVisibility = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private bool bEnabled = true;

	private TPerPlayer<UHealthBarWidget> HealthBars;
	UBossHealthBarWidget CoastBossHealthBar;
	private UBasicAIHealthComponent HealthComp;
	private UBasicAIHealthBarSettings Settings;
	ACoastBoss Boss;

#if EDITOR
	private FTimerHandle EditorUpdateHandle;
#endif

	// Bind a function to this delegate to override visibility
	FBasicAIHealthBarVisiblityDelegate ShouldShowHealthBarDelegate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Boss = Cast<ACoastBoss>(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		Settings = UBasicAIHealthBarSettings::GetSettings(Cast<AHazeActor>(Owner));
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");			
		SetupHealthBars();
		Boss.SyncedBossBP.SetValue(1.0);
	}

	bool IsBossHealthBar()
	{
		return HealthBarWidgetClass.Get().IsChildOf(UBossHealthBarWidget);
	} 

	UFUNCTION()
	void OnTakeDamage(AHazeActor Actor, AHazeActor Instigator, float Damage, EDamageType DamageType)
	{
		if (Actor != Owner)
			return;

		if (HealthComp.IsAlive())
		{
			UpdateHealthBarVisibility();
			if (Network::IsGameNetworked())
			{
				if (HealthComp.CurrentHealth < Boss.SyncedBossBP.Value)
					Boss.SyncedBossBP.SetValue(HealthComp.CurrentHealth);
				CoastBossHealthBar.SetHealthAsDamage(Boss.SyncedBossBP.Value);
			}
			else
				CoastBossHealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
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

		// Show health bars
		if (IsBossHealthBar())
		{
			// Show boss health bar
			if (CoastBossHealthBar == nullptr)
			{
				CoastBossHealthBar = Widget::AddFullscreenWidget(HealthBarWidgetClass);
				CoastBossHealthBar.InitBossHealthBar(BossHealthBarDesc, HealthComp.MaxHealth, Settings.HealthBarSegments);
				CoastBossHealthBar.SetHealthAsDamage(HealthComp.MaxHealth - HealthComp.CurrentHealth);
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
			if (CoastBossHealthBar != nullptr)
			{
				Widget::RemoveFullscreenWidget(CoastBossHealthBar);
				CoastBossHealthBar = nullptr;	
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

	// private void UpdateHealthBar(UHealthBarWidget HealthBar)
	// {
	// 	if (HealthBar == nullptr)
	// 		return;
	// 	HealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
	// }

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

		if (CoastBossHealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(CoastBossHealthBar);
			CoastBossHealthBar = nullptr;	
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

		if (CoastBossHealthBar != nullptr)
			CoastBossHealthBar.SetHealthAsDamage(HealthComp.CurrentHealth);
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
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBars();
	}
}
