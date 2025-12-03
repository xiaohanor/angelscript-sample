UCLASS(NotBlueprintable)
class UGravityBikeSplineEnemyHealthBarComponent : UActorComponent
{
	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	TSubclassOf<UHealthBarWidget> HealthBarWidgetClass;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName HealthBarAttachComponentName = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FName HealthBarAttachSocket = NAME_None;

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	FVector HealthBarOffset = FVector(0.0, 0.0, 180.0);

	UPROPERTY(EditAnywhere, BlueprintReadOnly)
	EBasicAIHealthBarVisibility HealthBarVisibility = EBasicAIHealthBarVisibility::OnlyShowWhenHurt;

	private UGravityBikeSplineEnemyHealthComponent HealthComp;
	private UHealthBarWidget HealthBar;
	private TArray<FInstigator> BlockingInstigators;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HealthComp = UGravityBikeSplineEnemyHealthComponent::Get(Owner);

		if(HealthComp == nullptr)
			return;

		HealthComp.PostTakeDamage.AddUFunction(this, n"PostTakeDamage");
		HealthComp.OnDeath.AddUFunction(this, n"OnDeath");
		HealthComp.OnRespawn.AddUFunction(this, n"OnRespawn");

		UpdateHealthBarVisibility();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		UpdateHealthBarVisibility();
	}

	UFUNCTION(BlueprintOverride)
	void OnActorDisabled()
	{
		RemoveHealthBar();
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		RemoveHealthBar();
	}

	void BlockHealthBar(FInstigator Instigator)
	{
		BlockingInstigators.AddUnique(Instigator);
		UpdateHealthBarVisibility();
	}

	void UnblockHealthBar(FInstigator Instigator)
	{
		BlockingInstigators.RemoveSingleSwap(Instigator);
		UpdateHealthBarVisibility();
	}

	UFUNCTION()
	private void PostTakeDamage(FGravityBikeSplineEnemyTakeDamageData DamageData)
	{
		if(HealthComp.IsDead())
			return;
		
		UpdateHealthBarVisibility();
		UpdateHealthBar();
	}

	UFUNCTION()
	private void OnDeath(FGravityBikeSplineEnemyDeathData DeathData)
	{
		RemoveHealthBar();
	}

	UFUNCTION()
	private void OnRespawn(FGravityBikeSplineEnemyRespawnData RespawnData)
	{
		UpdateHealthBarVisibility();
		UpdateHealthBar();
	}

	private void UpdateHealthBarVisibility()
	{
		if (!ShouldShowHealthBar())
		{
			RemoveHealthBar();
			return;			
		}

		// Show health bar
		if (HealthBar == nullptr)
			CreateHealthBarWidget();
	}

	private void CreateHealthBarWidget()
	{
		if (!HealthBarWidgetClass.IsValid())
			return;

		HealthBar = GravityBikeSpline::GetDriverPlayer().AddWidget(HealthBarWidgetClass);
		HealthBar.InitHealthBar(HealthComp.GetMaxHealth());

		USceneComponent AttachComp = USceneComponent::Get(Owner, HealthBarAttachComponentName);
		if (AttachComp == nullptr)
			AttachComp = Owner.RootComponent;

		HealthBar.AttachWidgetToComponent(AttachComp, HealthBarAttachSocket);
		HealthBar.SetWidgetRelativeAttachOffset(HealthBarOffset);
		HealthBar.SetHealthAsDamage(HealthComp.GetCurrentHealth());
	}

	private void UpdateHealthBar()
	{
		if (HealthBar == nullptr)
			return;

		HealthBar.SetHealthAsDamage(HealthComp.GetCurrentHealth());
	}

	private void RemoveHealthBar()
	{
		if (HealthBar != nullptr)
		{
			GravityBikeSpline::GetDriverPlayer().RemoveWidget(HealthBar);
			HealthBar = nullptr;
		}
	}

	private bool ShouldShowHealthBar()
	{
		if (!HealthBarWidgetClass.IsValid())
			return false;

		if (HealthComp.GetMaxHealth() < SMALL_NUMBER)
		 	return false;

		if(HealthComp.IsRespawning())
			return false;

		if(BlockingInstigators.Num() > 0)
			return false;

		switch (HealthBarVisibility) 
		{
			case EBasicAIHealthBarVisibility::AlwaysShow:
		 		return true;
		 	case EBasicAIHealthBarVisibility::OnlyShowWhenHurt:
		 		return (HealthComp.GetHealthFraction() < 1.0);
		}  
	}
};