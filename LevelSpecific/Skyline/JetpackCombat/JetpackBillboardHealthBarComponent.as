class UJetpackBillboardHealthBarComponent : UActorComponent
{
 	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
 	TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;

 	UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "GUI")
	FText Desc;

 	private UBossHealthBarWidget HealthBar;

 	float Health = 1.0;
	int Partitions = 1;

	void Initialize(int HealthPartitions)
	{
		Partitions = HealthPartitions;
	}

	void OnTakeDamage(float RemainingHealth)
	{
		Health = RemainingHealth;
		UpdateHealthBar();
	}

	void OnDestroyed()
	{
		RemoveHealthBar();
	}

	void ShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return;
		if (HealthBar != nullptr)
			return;
		HealthBar = Widget::AddFullscreenWidget(HealthBarWidgetClass);
		HealthBar.InitBossHealthBar(Desc, 1.0, Partitions);
		UpdateHealthBar();
	}

	void UpdateHealthBar()
	{
		if (HealthBar != nullptr)
			HealthBar.SetHealthAsDamage(Health);
	}

	void RemoveHealthBar()
	{
		if (HealthBar != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthBar);
			HealthBar = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		RemoveHealthBar();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		RemoveHealthBar();
	}
}


