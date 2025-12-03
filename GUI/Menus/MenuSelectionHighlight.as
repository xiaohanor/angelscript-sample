enum EMenuSelectionHighlightStyle
{
	Short,
	Long,
}

UCLASS(Abstract)
class UMenuSelectionHighlight : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UScalableSlicedImage SelectedBackground;
	UPROPERTY()
	bool bIsHighlighted = false;

	UPROPERTY(EditAnywhere, Category = "Menu Highlight")
	EMenuSelectionHighlightStyle Style = EMenuSelectionHighlightStyle::Short;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D Background_Mio;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D Background_Zoe;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D Background_Neutral;

	UPROPERTY(EditDefaultsOnly)
	UTexture2D Background_Mio_Long;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D Background_Zoe_Long;
	UPROPERTY(EditDefaultsOnly)
	UTexture2D Background_Neutral_Long;

	bool bIsZoe = false;
	bool bIsNeutral = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
		UpdateOwningPlayer();
		Update();
	}

	void UpdateOwningPlayer()
	{
		UHazeGameInstance HazeGameInstance = Game::HazeGameInstance;
		if (HazeGameInstance != nullptr)
		{
			switch (HazeGameInstance.PausingPlayer)
			{
				case EHazeSelectPlayer::Mio:
					bIsZoe = false;
					bIsNeutral = false;
				break;
				case EHazeSelectPlayer::Zoe:
					bIsZoe = true;
					bIsNeutral = false;
				break;
				default:
					bIsZoe = false;
					bIsNeutral = true;
				break;
			}
		}
		else
		{
			bIsZoe = false;
			bIsNeutral = true;
		}

	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		Update();
	}

	void Update()
	{
		if (bIsHighlighted)
		{
			switch (Style)
			{
				case EMenuSelectionHighlightStyle::Short:
					if (bIsZoe)
						SelectedBackground.SetBrushFromTexture(Background_Zoe);
					else if (bIsNeutral)
						SelectedBackground.SetBrushFromTexture(Background_Neutral);
					else
						SelectedBackground.SetBrushFromTexture(Background_Mio);
				break;
				case EMenuSelectionHighlightStyle::Long:
					if (bIsZoe)
						SelectedBackground.SetBrushFromTexture(Background_Zoe_Long);
					else if (bIsNeutral)
						SelectedBackground.SetBrushFromTexture(Background_Neutral_Long);
					else
						SelectedBackground.SetBrushFromTexture(Background_Mio_Long);
				break;
			}
			SelectedBackground.Visibility = ESlateVisibility::Visible;
		}
		else
		{
			SelectedBackground.Visibility = ESlateVisibility::Hidden;
		}
	}
}