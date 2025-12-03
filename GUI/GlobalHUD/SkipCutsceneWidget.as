class USkipCutsceneWidget : UHazeSkipCutsceneTwoPlayersWidget
{
	UPROPERTY(BindWidget)
	UImage LeftProgress;
	UPROPERTY(BindWidget)
	UImage RightProgress;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		auto LeftMaterial = LeftProgress.GetDynamicMaterial();
		LeftMaterial.SetScalarParameterValue(n"StartPercentage", 0.5);
		LeftMaterial.SetScalarParameterValue(n"EndPercentage", 0.5 + (LeftProgressValue*0.5));

		auto RightMaterial = RightProgress.GetDynamicMaterial();
		RightMaterial.SetScalarParameterValue(n"StartPercentage", 0.5 - (RightProgressValue*0.5));
		RightMaterial.SetScalarParameterValue(n"EndPercentage", 0.5);
	}
}