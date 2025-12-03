class UBattleFieldHoverboardPointsLostWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock LostPointsText;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		LostPointsText.DynamicFontMaterial.SetVectorParameterValue(n"TopColor", FLinearColor::Black);
		LostPointsText.DynamicFontMaterial.SetVectorParameterValue(n"BottomColor", FLinearColor::Red * 1.5);
	}
}