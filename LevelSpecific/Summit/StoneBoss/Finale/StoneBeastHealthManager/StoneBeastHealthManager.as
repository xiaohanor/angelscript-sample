UCLASS(Abstract)
class AStoneBeastHealthManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedActorComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarClass;
	UBossHealthBarWidget HealthBarWidget;

	const float MaxStoneBeastHealth = 4.0;
	float CurrentStoneBeastHealth = 4.0;

	UFUNCTION(BlueprintCallable)
	void ShowStoneBeastHealth()
	{
		HealthBarWidget = Widget::AddFullscreenWidget(HealthBarClass);
		HealthBarWidget.InitBossHealthBar(FText::FromString("StoneBeast"), MaxStoneBeastHealth, 4);
		HealthBarWidget.SnapHealthTo(CurrentStoneBeastHealth);
	}

	UFUNCTION(BlueprintCallable)
	void HideStoneBeastHealth()
	{
		Widget::RemoveFullscreenWidget(HealthBarWidget);
	}

	void SetStoneBeastHealth(float Value)
	{
		CurrentStoneBeastHealth = Value;
		UpdateHealthBar();
	}

	UFUNCTION(BlueprintCallable)
	void DamageStoneBeast(float Damage)
	{
		CurrentStoneBeastHealth = Math::Max(0, CurrentStoneBeastHealth - Damage);
		Print(f"{CurrentStoneBeastHealth=}");
		UpdateHealthBar();
	}

	UFUNCTION(BlueprintCallable)
	void SetWeakpointTarget(int TargetWeakpoint)
	{
		SetStoneBeastHealth(MaxStoneBeastHealth - TargetWeakpoint);
	}

	void UpdateHealthBar()
	{
		if (HealthBarWidget != nullptr)
			HealthBarWidget.SetHealthAsDamage(CurrentStoneBeastHealth);
	}
};