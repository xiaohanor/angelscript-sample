UCLASS(Abstract)
class UEnemyPortraitWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage PortraitImage;

	UPROPERTY(BindWidget)
	UTextBlock PortraitName;

	UPROPERTY(BindWidget)
	UProgressBar PortraitHealth;

	UPROPERTY(BindWidget)
	UBorder DeadOverlay;

	UPROPERTY(BindWidget)
	UBorder DamageOverlay;

	FHazeAcceleratedFloat DamageOpacity;

	FHazeAcceleratedFloat AnimationAlpha;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DeadOverlay.SetVisibility(ESlateVisibility::Hidden);
		DamageOverlay.SetVisibility(ESlateVisibility::Visible);
		DamageOverlay.RenderOpacity = 0.0;
		AnimationAlpha.SnapTo(0.0);

		RenderScale = FVector2D(AnimationAlpha.Value, AnimationAlpha.Value);
		RenderOpacity = AnimationAlpha.Value;
		RenderTranslation = FVector2D(AnimationAlpha.Value, (1.0 - AnimationAlpha.Value) * 300.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		DamageOpacity.AccelerateTo(0.0, 1.0, InDeltaTime);
		DamageOverlay.RenderOpacity = DamageOpacity.Value;

		AnimationAlpha.AccelerateTo(1.0, 3.0, InDeltaTime);
		RenderScale = FVector2D(AnimationAlpha.Value, AnimationAlpha.Value) * (1.0 + DamageOpacity.Value * 0.15);
		RenderOpacity = AnimationAlpha.Value;
		RenderTranslation = FVector2D(AnimationAlpha.Value, (1.0 - AnimationAlpha.Value) * 300.0);
	}

	UFUNCTION(NotBlueprintCallable)
	private void HandleSpawn(AHazeActor SpawnedActor)
	{
		auto HealthComp = UBasicAIHealthComponent::Get(SpawnedActor);
		HealthComp.OnTakeDamage.AddUFunction(this, n"HandleTakeDamage");
		HealthComp.OnDie.AddUFunction(this, n"HandleDie");
	}

	UFUNCTION(NotBlueprintCallable)
	private void HandleTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		auto HealthComp = UBasicAIHealthComponent::Get(ActorTakingDamage);
		PortraitHealth.SetPercent(HealthComp.CurrentHealth / HealthComp.MaxHealth);
	
		DamageOpacity.SnapTo(1.0);
/*
		if (HealthComp.CurrentHealth <= 0.0)
		{
			DeadOverlay.SetVisibility(ESlateVisibility::Visible);
			HealthComp.OnTakeDamage.Unbind(this, n"HandleTakeDamage");
		}
*/
	}

	UFUNCTION()
	private void HandleDie(AHazeActor ActorBeingKilled)
	{
		DeadOverlay.SetVisibility(ESlateVisibility::Visible);

		auto HealthComp = UBasicAIHealthComponent::Get(ActorBeingKilled);
		HealthComp.OnTakeDamage.Unbind(this, n"HandleTakeDamage");
		HealthComp.OnDie.Unbind(this, n"HandleDie");
	}
};

UCLASS(Abstract)
class UEnemyPortraitBarWidget : UHazeUserWidget
{
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly)
	TSubclassOf<UEnemyPortraitWidget> PortraitClass;
	TArray<UEnemyPortraitWidget> PortraitWidgets;

	UPROPERTY(BindWidget)
	UTextBlock Title;

	UPROPERTY(BindWidget)
	UHorizontalBox PortraitBar;

	void AddPortrait(UEnemyPortraitComponent PortraitComp)
	{
		auto Portrait = Cast<UEnemyPortraitWidget>(Widget::CreateWidget(this, PortraitClass));
		Portrait.PortraitImage.SetBrushFromTexture(PortraitComp.PortraitImage);
		Portrait.PortraitName.Text = FText::FromName(PortraitComp.PortraitName);

		auto HealthComp = UBasicAIHealthComponent::Get(PortraitComp.Owner);
		HealthComp.OnTakeDamage.AddUFunction(Portrait, n"HandleTakeDamage");
		HealthComp.OnDie.AddUFunction(Portrait, n"HandleDie");

		PortraitBar.AddChildToHorizontalBox(Portrait);
	}

	void AddPortraitFromSpawner(UEnemyPortraitComponent PortraitComp)
	{
		auto Portrait = Cast<UEnemyPortraitWidget>(Widget::CreateWidget(this, PortraitClass));
		Portrait.PortraitImage.SetBrushFromTexture(PortraitComp.PortraitImage);
		Portrait.PortraitName.Text = FText::FromName(PortraitComp.PortraitName);

		auto Spawner = Cast<AHazeActorSpawnerBase>(PortraitComp.Owner);
		Spawner.OnPostSpawn.AddUFunction(Portrait, n"HandleSpawn");

		PortraitBar.AddChildToHorizontalBox(Portrait);
	}	
};