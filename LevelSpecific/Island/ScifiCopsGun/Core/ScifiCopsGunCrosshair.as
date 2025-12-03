

enum EScifiCopsGunCrosshairType
{
	None,
	Aim,
	Shoot
}

UCLASS(Abstract)
class UScifiCopsGunCrosshair : UCrosshairWidget
{	
	// Editabe Variables
	const FLinearColor ShootColor = FLinearColor::Gray;
	const FLinearColor ShootAtTargetColor = FLinearColor::White;
	const FLinearColor AimColor = FLinearColor::Gray;
	const FLinearColor AimAtTargetColor = FLinearColor::White;

	bool bAiming = false;
	bool bHasAimTarget = false;

	bool bShooting = false;
	bool bHasShootTarget = false;

	EScifiCopsGunCrosshairType LastActiveType = EScifiCopsGunCrosshairType::None;

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(bShooting)
			LastActiveType = EScifiCopsGunCrosshairType::Shoot;
		else if(bAiming)
			LastActiveType = EScifiCopsGunCrosshairType::Aim;
	}

	UFUNCTION(BlueprintPure)
	EScifiCopsGunCrosshairType GetActiveWidgetType() const
	{
		return LastActiveType;
	}

	UFUNCTION(BlueprintPure)
	FSlateColor GetPaintColor() const
	{	
		FSlateColor CurrentColor;
		CurrentColor.ColorUseRule = ESlateColorStylingMode::UseColor_Specified;
		CurrentColor.SpecifiedColor = FLinearColor(1, 1, 1, 1);		
		
		if(LastActiveType == EScifiCopsGunCrosshairType::Shoot)
		{
			if(!bHasShootTarget)
				CurrentColor.SpecifiedColor = ShootColor;
			else
				CurrentColor.SpecifiedColor = ShootAtTargetColor;
		}
		else if(LastActiveType == EScifiCopsGunCrosshairType::Aim)
		{
			if(!bHasAimTarget)
				CurrentColor.SpecifiedColor = AimColor;
			else
				CurrentColor.SpecifiedColor = AimAtTargetColor;
		}

		return CurrentColor;
	}
};