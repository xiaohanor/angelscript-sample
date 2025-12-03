class USolarFlareTriggerShieldEnergyWidget : UHazeUserWidget
{	
	UPROPERTY(BindWidget)
	UImage EnergyBar;

	void SetWidgetShieldEnergy(float Value) 
	{
		auto DynamicMaterial = EnergyBar.GetDynamicMaterial();
		DynamicMaterial.SetScalarParameterValue(n"StartPercentage", 0.0);
		DynamicMaterial.SetScalarParameterValue(n"EndPercentage", Value);
	}

	UFUNCTION()
	void ApplyColor(FLinearColor NewColor)
	{
		EnergyBar.SetColorAndOpacity(NewColor);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if (Player != nullptr && Player.IsPlayerDead())
			SetRenderOpacity(Math::FInterpConstantTo(RenderOpacity, 0.0, InDeltaTime, 10.0));
		else
			SetRenderOpacity(Math::FInterpConstantTo(RenderOpacity, 1.0, InDeltaTime, 10.0));
	}
}