UCLASS(Abstract)
class UMenuPanelContainer : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage HeaderLine;

	UPROPERTY(EditAnywhere, Category = "Menu Panel")
	bool bShowHeaderLine = true;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D HeaderLine_Neutral;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HeaderLine_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D HeaderLine_Zoe;

	UFUNCTION(BlueprintOverride)
	void PreConstruct(bool IsDesignTime)
	{
		if (bShowHeaderLine)
			HeaderLine.Visibility = ESlateVisibility::HitTestInvisible;
		else
			HeaderLine.Visibility = ESlateVisibility::Hidden;
	}

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UHazeGameInstance HazeGameInstance = Game::HazeGameInstance;
		if (HazeGameInstance != nullptr)
		{
			switch (HazeGameInstance.PausingPlayer)
			{
				case EHazeSelectPlayer::Mio:
					HeaderLine.SetBrushFromTexture(HeaderLine_Mio);
				break;
				case EHazeSelectPlayer::Zoe:
					HeaderLine.SetBrushFromTexture(HeaderLine_Zoe);
				break;
				default:
					HeaderLine.SetBrushFromTexture(HeaderLine_Neutral);
				break;
			}
		}
		else
		{
			HeaderLine.SetBrushFromTexture(HeaderLine_Neutral);
		}
	}
}