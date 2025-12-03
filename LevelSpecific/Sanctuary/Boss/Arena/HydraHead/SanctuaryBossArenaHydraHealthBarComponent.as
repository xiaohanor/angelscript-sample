
class USanctuaryBossArenaHydraHealthBarComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private TSubclassOf<USanctuaryBossArenaHydraHealthBarBossWidget> HealthBarWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private FText BossHealthBarDesc;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	private EHazeSelectPlayer PlayerVisibility = EHazeSelectPlayer::Both;

	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	bool bEnabled = true;

	bool bUseHealthComp = true;

	USanctuaryBossArenaHydraHealthBarBossWidget HydraBossHealthBar;
	private UBasicAIHealthComponent HealthComp;

	int HealthBarSegments = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bUseHealthComp)
		{
			HealthComp = UBasicAIHealthComponent::Get(Owner);
			HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		}
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr)
			RespawnComp.OnPostRespawn.AddUFunction(this, n"OnRespawn");			
		SetupHealthBars();
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
			UpdateHealthBar(HydraBossHealthBar);
		}
		else // Dead
		{
			RemoveHealthBars();
		}
	}

	private float GetMaxHealth()
	{
		return HealthComp != nullptr ? HealthComp.MaxHealth : 1.0 ;
	}

	private float GetCurrentHealth()
	{
		return HealthComp != nullptr ? HealthComp.CurrentHealth : HydraBossHealthBar.Health;
	}

	protected bool ShouldShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return false;

		return true;
	}

	void SetupHealthBars()
	{
		if (HealthBarWidgetClass.IsValid())
		{
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

		// Show boss health bar
		if (HydraBossHealthBar == nullptr)
		{
			HydraBossHealthBar = Widget::AddFullscreenWidget(HealthBarWidgetClass);
			HydraBossHealthBar.InitBossHealthBar(BossHealthBarDesc, GetCurrentHealth(), HealthBarSegments);
		}

	}

	private UHealthBarWidget AddHealthBarWidget(AHazePlayerCharacter Player)
	{
		if (!HealthBarWidgetClass.IsValid())
			return nullptr;

		UHealthBarWidget HealthBar = Player.AddWidget(HealthBarWidgetClass);
		HealthBar.InitHealthBar(GetCurrentHealth());
		return HealthBar;
	}

	void RefreshHealthValue()
	{		
		UpdateHealthBarVisibility();
		UpdateHealthBar(HydraBossHealthBar);
	}

	private void UpdateHealthBar(UHealthBarWidget HealthBar)
	{
		if (HealthBar == nullptr)
			return;
		HealthBar.SetHealthAsDamage(GetCurrentHealth());
	}

	void RemoveHealthBars()
	{
		if (HydraBossHealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(HydraBossHealthBar);
			HydraBossHealthBar = nullptr;	
		}
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
