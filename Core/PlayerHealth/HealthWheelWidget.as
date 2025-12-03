
UCLASS(Abstract)
class UHealthWheelWidget : UHazeUserWidget
{
	UPROPERTY(Meta = (BindWidget))
	UImage WheelImage;

	// Whether this is a right side or left side wheel
	UPROPERTY()
	bool bIsRightSide = false;

	// Fraction of health below which to permanently display damaged state
	UPROPERTY()
	float CriticalHealthPercentage = 0.15;

	// How long after damage is over to display damaged status
	UPROPERTY()
	float DamagedLingerTimeSeconds = 1.0;

	// How fast the healing state lerps in and out
	UPROPERTY()
	float HealingStateLerpSpeed = 7.0;

	FHealthValue Health;

	private UMaterialInstanceDynamic DynamicMaterial;

	private float DisplayCurrentHealth = 0.0;
	private float DisplayTargetHealth = 0.0;
	private float DisplayDamaged = 0.0;
	private float DisplayHealing = 0.0;

	private bool bIsRegenerating = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		DynamicMaterial = WheelImage.GetDynamicMaterial();
		SetRightSide(bIsRightSide);
	}

	void SetRightSide(bool bRightSide)
	{
		bIsRightSide = bRightSide;
		DynamicMaterial.SetScalarParameterValue(n"IsRightSide", bIsRightSide ? 1.0 : 0.0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry Geom, float DeltaTime)
	{
		float NewCurrentHealth = Health.CurrentHealth - Health.GetDisplayRegenerationAmount() + Health.GetDisplayDamageAmount();
		if (NewCurrentHealth != DisplayCurrentHealth)
		{
			DynamicMaterial.SetScalarParameterValue(n"CurrentHealth", NewCurrentHealth);
			DisplayCurrentHealth = NewCurrentHealth;
		}

		float NewTargetHealth = Health.GetDisplayHealth();
		if (NewTargetHealth != DisplayTargetHealth)
		{
			DynamicMaterial.SetScalarParameterValue(n"TargetHealth", NewTargetHealth);
			DisplayTargetHealth = NewTargetHealth;
		}

		bool bShowDamaged = (Health.CurrentHealth < CriticalHealthPercentage) || (Health.RecentlyLostHealth > 0.0);
		float NewDamaged = 0.0;
		if (bShowDamaged)
			NewDamaged = 1.0;
		else
			NewDamaged = Math::FInterpConstantTo(DisplayDamaged, 0.0, DeltaTime, 1.0 / DamagedLingerTimeSeconds);

		if (NewDamaged != DisplayDamaged)
		{
			DynamicMaterial.SetScalarParameterValue(n"Damaged", NewDamaged);
			DisplayDamaged = NewDamaged;
		}

		if (Health.RecentlyRegeneratedHealth > 0.0 || Health.RecentlyHealedHealth > 0.0)
		{
			if (DisplayHealing < 1.0)
			{
				DisplayHealing = Math::FInterpConstantTo(DisplayHealing, 1.0, DeltaTime, HealingStateLerpSpeed);
				DynamicMaterial.SetScalarParameterValue(n"IsHealing", DisplayHealing);
			}
		}
		else
		{
			if (DisplayHealing > 0.0)
			{
				DisplayHealing = Math::FInterpConstantTo(DisplayHealing, 0.0, DeltaTime, HealingStateLerpSpeed);
				DynamicMaterial.SetScalarParameterValue(n"IsHealing", DisplayHealing);
			}
		}
	}
};