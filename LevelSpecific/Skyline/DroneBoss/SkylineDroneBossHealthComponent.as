event void FSkylineDroneBossDamageTakenSignature(float Damage);

class USkylineDroneBossHealthComponent : UActorComponent
{
	UPROPERTY(EditDefaultsOnly, BlueprintReadOnly)
	FText BossName;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	float MaxHealth = 1.0;
	
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TSubclassOf<UBossHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY()
	FSkylineDroneBossDamageTakenSignature OnDamageTaken;

	float Health = 1.0;

	ASkylineDroneBoss Boss;
	UBossHealthBarWidget HealthBarWidget;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Health = MaxHealth;
		Boss = Cast<ASkylineDroneBoss>(Owner);

		if (HealthBarWidgetClass != nullptr)
		{
			HealthBarWidget = Cast<UBossHealthBarWidget>(
				Widget::AddFullscreenWidget(HealthBarWidgetClass, EHazeWidgetLayer::PlayerHUD)
			);
			HealthBarWidget.InitBossHealthBar(BossName, MaxHealth, Boss.Phases.Num());
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