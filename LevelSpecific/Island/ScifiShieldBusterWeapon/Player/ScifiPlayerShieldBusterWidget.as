UCLASS(Abstract)
class UScifiPlayerShieldBusterCrosshair : UCrosshairWidget
{	
	//float ShootingAlpha = 0;

	UFUNCTION(BlueprintPure)
	FSlateColor GetPaintColor() const
	{	
		FSlateColor CurrentColor;
		CurrentColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		CurrentColor.SpecifiedColor = FLinearColor(1, 1, 1, 1);		
		return CurrentColor;
	}
};

