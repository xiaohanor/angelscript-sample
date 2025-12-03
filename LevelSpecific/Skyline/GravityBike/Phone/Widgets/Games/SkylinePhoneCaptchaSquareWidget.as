UCLASS(Abstract)
class USkylinePhoneCaptchaSquareWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage Image;

	private bool bIsSelected = false;

	UFUNCTION(BlueprintPure)
	bool IsSelected() const
	{
		return bIsSelected;
	}

	void Click()
	{
		bIsSelected = !bIsSelected;

		if(bIsSelected)
			OnSelected();
		else
			OnDeselected();
	}

	UFUNCTION(BlueprintEvent)
	private void OnSelected(){}

	UFUNCTION(BlueprintEvent)
	private void OnDeselected(){}

	UFUNCTION(BlueprintEvent)
	private void OnNewSlide(){}

	void NewSlide()
	{
		OnNewSlide();
		bIsSelected = false;
	}
}