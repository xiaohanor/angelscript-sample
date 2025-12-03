event void FSanctuaryMoleCombatBossDamageTakenSignature(float Damage);

class USanctuaryMoleCombatHealthComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	FText BossName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MaxHealth = 1.0;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY()
	FSanctuaryMoleCombatBossDamageTakenSignature OnDamageTaken;

	float Health = 1.0;

	AMoleCombatManager Boss;
	private UBossHealthBarWidget HealthBarWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Health = MaxHealth;
		Boss = Cast<AMoleCombatManager>(Owner);
	}

	void SpawnHealthBar()
	{
		if (HealthBarWidgetClass != nullptr)
		{
			HealthBarWidget = Cast<UBossHealthBarWidget>(
				Widget::AddFullscreenWidget(HealthBarWidgetClass, EHazeWidgetLayer::PlayerHUD)
			);
			HealthBarWidget.InitBossHealthBar(BossName, MaxHealth, Boss.Wave2Moles);
		}
	}

	void RemoveHealthBar()
	{
		if (HealthBarWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthBarWidget);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (HealthBarWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthBarWidget);
		}

		HealthBarWidget = nullptr;
	}

	UFUNCTION(BlueprintCallable)
	void TakeDamage(float Damage)
	{
		Health = Math::Clamp(Health - Damage, 0.0, MaxHealth);
		HealthBarWidget.TakeDamage(Damage);
		OnDamageTaken.Broadcast(Damage);
	}
};