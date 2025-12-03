UCLASS(Abstract)
class URemoteHackableStockMarketWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UImage CurrentArrowImage;

	UPROPERTY(BindWidget)
	UTextBlock CurrentValueText;

	UPROPERTY(BindWidget)
	UTextBlock DayChangeText;

	UPROPERTY(BindWidget)
	UBorder CurrentChangeBorder;

	UPROPERTY(BindWidget)
	UTextBlock CurrentChangeText;

	UPROPERTY(BindWidget)
	USlider LineSlider;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor PositiveColor = FLinearColor::Green;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor NeutralColor = FLinearColor::White;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor NegativeColor = FLinearColor::Red;

	UPROPERTY(EditDefaultsOnly)
	TArray<FText> GreatNews;

	UPROPERTY(EditDefaultsOnly)
	TArray<FText> PositiveNews;

	UPROPERTY(EditDefaultsOnly)
	TArray<FText> NeutralNews;

	UPROPERTY(EditDefaultsOnly)
	TArray<FText> NegativeNews;

	UPROPERTY(EditDefaultsOnly)
	TArray<FText> HorribleNews;

	private ARemoteHackableStockMarket StockMarket;

	float LastUpdateTime = -1;
	float PreviousValue;

	float LastNewsTime = -1;
	bool bIsDisplayingNews = false;

	UFUNCTION(BlueprintOverride)
	void Construct()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(FGeometry MyGeometry, float InDeltaTime)
	{
		if(StockMarket == nullptr)
			return;

		LineSlider.SetValue(StockMarket.InputValue);

		if(Time::GetGameTimeSince(LastUpdateTime) > 1)
		{
			UpdateValues();
		}

		if(StockMarket.HackingComp.IsHacked())
		{
			if(Time::GetGameTimeSince(LastNewsTime) > 5)
			{
				if(bIsDisplayingNews)
					BP_PopNews();
				else
				{
					bIsDisplayingNews = true;
					BP_PushNews(SelectNews());
				}

				LastNewsTime = Time::GameTimeSeconds;
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void BP_PushNews(FText Text)
	{
	}

	UFUNCTION(BlueprintEvent)
	void BP_PopNews()
	{
	}

	UFUNCTION(BlueprintCallable)
	void OnNewsPopped()
	{
		check(bIsDisplayingNews);

		if(StockMarket.HackingComp.IsHacked())
		{
			BP_PushNews(SelectNews());
		}
		else
		{
			bIsDisplayingNews = false;
		}
	}

	FText SelectNews() const
	{
		bool bIsGreat = GetDayChangePercent() > 50;
		bool bIsPositive = GetDayChangePercent() > 5;
		bool bIsNegative = GetDayChangePercent() < -5;
		bool bIsHorrible = GetDayChangePercent() < -50;

		if(bIsGreat)
		{
			return GreatNews[Math::RandRange(0, GreatNews.Num() - 1)];
		}
		else if(bIsHorrible)
		{
			return HorribleNews[Math::RandRange(0, HorribleNews.Num() - 1)];
		}
		else if(bIsPositive)
		{
			return PositiveNews[Math::RandRange(0, PositiveNews.Num() - 1)];
		}
		else if(bIsNegative)
		{
			return NegativeNews[Math::RandRange(0, NegativeNews.Num() - 1)];
		}
		else
		{
			return NeutralNews[Math::RandRange(0, NeutralNews.Num() - 1)];
		}
	}

	void SetStockMarket(ARemoteHackableStockMarket InStockMarket)
	{
		StockMarket = InStockMarket;
		PreviousValue = StockMarket.StockValue;
		UpdateValues();
	}

	void UpdateValues()
	{
		LastUpdateTime = Time::GameTimeSeconds;

		UpdateStockValue();
		UpdateDayChange();
		UpdateCurrentChange();

		PreviousValue = StockMarket.StockValue;
	}

	void UpdateStockValue()
	{
		const float DeltaValue = GetDeltaValue();

		if(DeltaValue > 0)
		{
			CurrentArrowImage.SetRenderTransformAngle(-90);
			CurrentArrowImage.SetColorAndOpacity(PositiveColor);
		}
		else
		{
			CurrentArrowImage.SetRenderTransformAngle(90);
			CurrentArrowImage.SetColorAndOpacity(NegativeColor);
		}

		if(StockMarket.StockValue > 10)
		{
			CurrentValueText.SetColorAndOpacity(NeutralColor);
			CurrentValueText.SetText(FText::AsCultureInvariant(f"${StockMarket.StockValue:.2f}"));
		}
		else if(StockMarket.StockValue < KINDA_SMALL_NUMBER)
		{
			CurrentValueText.SetColorAndOpacity(NegativeColor);
			CurrentValueText.SetText(FText::AsCultureInvariant(":("));
		}
		else
		{
			if(StockMarket.StockValue < 1)
				CurrentValueText.SetColorAndOpacity(NegativeColor);
			else
				CurrentValueText.SetColorAndOpacity(NeutralColor);

			CurrentValueText.SetText(FText::AsCultureInvariant(f"${StockMarket.StockValue:.5f}"));
		}
	}

	float GetDeltaValue() const
	{
		return StockMarket.StockValue - PreviousValue;
	}

	void UpdateDayChange()
	{
		const float DayChangePercent = GetDayChangePercent();

		if(DayChangePercent > 0)
		{
			DayChangeText.SetText(FText::AsCultureInvariant(f"+{DayChangePercent:.2f}%"));
			DayChangeText.SetColorAndOpacity(PositiveColor);
		}
		else
		{
			DayChangeText.SetText(FText::AsCultureInvariant(f"{DayChangePercent:.2f}%"));
			DayChangeText.SetColorAndOpacity(NegativeColor);
		}
	}

	float GetDayChangePercent() const
	{
		return ((StockMarket.StockValue / StockMarket.InitialStockValue) * 100) - 100;
	}

	void UpdateCurrentChange()
	{
		if(StockMarket.StockValue < KINDA_SMALL_NUMBER || PreviousValue < KINDA_SMALL_NUMBER)
		{
			PreviousValue = StockMarket.StockValue;

			CurrentChangeText.SetText(FText::AsCultureInvariant("0%"));
			return;
		}

		const float CurrentChangePercent = GetCurrentChangePercent();

		if(CurrentChangePercent > 0)
		{
			CurrentChangeText.SetText(FText::AsCultureInvariant(f"+{CurrentChangePercent:.2f}%"));
		}
		else
		{
			CurrentChangeText.SetText(FText::AsCultureInvariant(f"{CurrentChangePercent:.2f}%"));
		}
	}

	float GetCurrentChangePercent() const
	{
		return ((StockMarket.StockValue / PreviousValue) * 100) - 100;
	}
};