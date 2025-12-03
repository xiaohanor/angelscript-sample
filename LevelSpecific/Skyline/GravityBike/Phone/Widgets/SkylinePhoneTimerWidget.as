UCLASS(Abstract)
class USkylinePhoneTimerWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	private UTextBlock Timer;

	void SetTimeLeft(float NewTime)
	{
		auto Text = FText::FromString(f"{NewTime:.2f}");
		Timer.SetText(Text);
	}

	UFUNCTION(BlueprintEvent)
	void BP_SmallWarning()
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_BigWarning()
	{
	}
}