class UMainMenuBackgroundWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock MenuTitle;
	UPROPERTY(BindWidget)
	UImage TitleArrow;
	UPROPERTY(BindWidget)
	UImage ButtonBackground;

	void SetMenuTitle(FText Text)
	{
		MenuTitle.SetText(Text);
		if (Text.IsEmpty())
		{
			MenuTitle.Visibility = ESlateVisibility::Collapsed;
			TitleArrow.Visibility = ESlateVisibility::Collapsed;
		}
		else
		{
			MenuTitle.Visibility = ESlateVisibility::HitTestInvisible;
			TitleArrow.Visibility = ESlateVisibility::HitTestInvisible;
		}
	}

	void SetShowButtonBar(bool bShowButtonBar)
	{
		if (bShowButtonBar)
			ButtonBackground.Visibility = ESlateVisibility::HitTestInvisible;
		else
			ButtonBackground.Visibility = ESlateVisibility::Hidden;
	}
}