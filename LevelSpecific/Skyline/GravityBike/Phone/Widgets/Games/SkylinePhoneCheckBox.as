UCLASS(Abstract)
class USkylinePhoneCheckBox : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage Outline;

	UPROPERTY(BindWidget)
	UImage Checkmark;

	UPROPERTY(BindWidget)
	USizeBox SizeBox;

	bool bIsChecked = false;

	FVector2D Position;
	FVector2D Size;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		Checkmark.SetRenderOpacity(bIsChecked ? 1 : 0);
		Size = FVector2D::UnitVector * SizeBox.WidthOverride;
	}

	void Check()
	{
		bIsChecked = !bIsChecked;
		Checkmark.SetRenderOpacity(bIsChecked ? 1 : 0);
	}

	void SetOutlineRed()
	{
		Outline.SetColorAndOpacity(FLinearColor::Red);
		Outline.SetBrushTintColor(FLinearColor::Red);

		if(bIsChecked)
			Outline.SetRenderScale(FVector2D(1.08, 1.08));
		else
			Outline.SetRenderScale(FVector2D(1.05, 1.05));
	}

	void ClearOutlineRed()
	{
		Outline.SetColorAndOpacity(FLinearColor::Black);
		Outline.SetBrushTintColor(FLinearColor::Black);
		Outline.SetRenderScale(FVector2D(1, 1));
	}
}