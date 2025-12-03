
UCLASS(Abstract)
class UBossHealthBarWidget : UHealthBarWidget
{
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HealthBar")
	FText BossName;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "HealthBar")
	int NumHealthSegments;

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void InitBossHealthBar(FText InBossName, float InMaxHealth, int InNumSegments = 1)
	{
		InitHealthBar(InMaxHealth);
		BossName = InBossName;
		NumHealthSegments = InNumSegments;

		for (AHazePlayerCharacter ActivePlayer : Game::Players)
			UPlayerHealthComponent::Get(ActivePlayer).IsBossHealthBarVisible.Apply(true, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		for (AHazePlayerCharacter ActivePlayer : Game::Players)
			UPlayerHealthComponent::Get(ActivePlayer).IsBossHealthBarVisible.Apply(false, this);
	}
}

UCLASS(Abstract)
class UBossHealthBarDefault : UBossHealthBarWidget
{
	default RecentDamageLerpDelay = 0.25;

	UPROPERTY(BindWidget)
	UHazeTextWidget BossNameLabel;
	UPROPERTY(BindWidget)
	UImage BarGradient;
	UPROPERTY(BindWidget)
	UHorizontalBox DividerBox;
	
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Damage;
	UPROPERTY(BindWidgetAnim)
	UWidgetAnimation Damage_Big;

	UPROPERTY(Interp)
	float HealthLerpInPercentage = 1.0;

	UPROPERTY()
	TSubclassOf<UHazeUserWidget> DividerWidget;

	float LastDisplayedDamage = 0.0;

	UFUNCTION(BlueprintOverride)
	void InitBossHealthBar(FText InBossName, float InMaxHealth, int InNumSegments)
	{
		Super::InitBossHealthBar(InBossName, InMaxHealth, InNumSegments);
		BossNameLabel.SetText(InBossName);

		// for (int i = 0; i < NumHealthSegments; ++i)
		// {
		// 	UHazeUserWidget Divider = Widget::CreateWidget(this, DividerWidget);
		// 	if (i == NumHealthSegments-1)
		// 		Divider.SetVisibility(ESlateVisibility::Hidden);

		// 	auto DividerSlot = Cast<UHorizontalBoxSlot>(DividerBox.AddChild(Divider));
		// 	FSlateChildSize ChildSize;
		// 	ChildSize.SizeRule = ESlateSizeRule::Fill;
		// 	DividerSlot.SetSize(ChildSize);
		// 	DividerSlot.SetHorizontalAlignment(EHorizontalAlignment::HAlign_Right);
		// 	DividerSlot.SetPadding(FMargin(0, 0, -5, 0));
		// }
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float DeltaTime)
	{
		Super::Tick(MyGeometry, DeltaTime);

		float DisplayedDamage = GetRecentDamagePercentage() - GetHealthPercentage();

		auto BarMaterial = BarGradient.GetDynamicMaterial();
		BarMaterial.SetScalarParameterValue(n"PercentageFilled", GetHealthPercentage() * HealthLerpInPercentage);
		BarMaterial.SetScalarParameterValue(n"PercentageDamage", DisplayedDamage);

		const bool bWasHit = DisplayedDamage > LastDisplayedDamage;
		if (bWasHit && !IsPlayingAnimation())
			PlayAnimation(Damage_Big);

		LastDisplayedDamage = DisplayedDamage;
	}

}