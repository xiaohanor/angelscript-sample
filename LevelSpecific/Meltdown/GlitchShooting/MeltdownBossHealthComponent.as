class UMeltdownBossHealthComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TSubclassOf<UBossHealthBarWidget> WidgetClass;
	UPROPERTY(EditAnywhere)
	float TotalBossHealth = 30.0;
	UPROPERTY(EditAnywhere)
	int HealthSegments = 3;
	UPROPERTY(EditAnywhere)
	bool bShowHealthFromStart = true;

	float CurrentHealth = 1.0;
	UBossHealthBarWidget HealthWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (bShowHealthFromStart)
			ShowHealthBar();
	}

	UFUNCTION(BlueprintCallable)
	void HideHealthBar()
	{
		if (HealthWidget != nullptr && HealthWidget.bIsAdded)
			Widget::RemoveFullscreenWidget(HealthWidget);
	}

	UFUNCTION(BlueprintCallable)
	void ShowHealthBar()
	{
		if (WidgetClass != nullptr && HealthWidget == nullptr)
		{
			HealthWidget = Widget::AddFullscreenWidget(WidgetClass, EHazeWidgetLayer::PlayerHUD);
			CurrentHealth = TotalBossHealth;
			HealthWidget.InitBossHealthBar(NSLOCTEXT("Meltdown", "BossName", "Rader"), TotalBossHealth, HealthSegments);
		}

		if (HealthWidget != nullptr && !HealthWidget.bIsAdded)
			Widget::AddExistingFullscreenWidget(HealthWidget, EHazeWidgetLayer::PlayerHUD);
	}


	void SetCurrentHealth(float Health)
	{
		CurrentHealth = Health;
		HealthWidget.SnapHealthTo(Health);
	}

	void Damage(float Damage)
	{
		CurrentHealth -= Damage;
		if (HealthWidget != nullptr)
			HealthWidget.TakeDamage(Damage);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		if (HealthWidget != nullptr)
			Widget::RemoveFullscreenWidget(HealthWidget);
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		if (HealthWidget != nullptr)
			Widget::AddExistingFullscreenWidget(HealthWidget, EHazeWidgetLayer::PlayerHUD);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (HealthWidget != nullptr)
		{
			Widget::RemoveFullscreenWidget(HealthWidget);
			HealthWidget = nullptr;
		}
	}
};