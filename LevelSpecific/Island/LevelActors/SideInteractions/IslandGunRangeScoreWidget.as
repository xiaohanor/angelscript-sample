class UIslandGunRangeScoreWidget : UHazeUserWidget
{
	UPROPERTY(BindWidget)
	UTextBlock ScoreText;

	UPROPERTY(BindWidget)
	UIslandGunRangeStarWidget OneStar;

	UPROPERTY(BindWidget)
	UIslandGunRangeStarWidget TwoStar;

	UPROPERTY(BindWidget)
	UIslandGunRangeStarWidget ThreeStar;

	int CurrentStar = 0;

	void Reset()
	{
		SetScore(0);
		
		if(CurrentStar > 0)
			OneStar.ResetStar();
		if(CurrentStar > 1)
			TwoStar.ResetStar();
		if(CurrentStar > 2)
			ThreeStar.ResetStar();

		CurrentStar = 0;
	}

	void SetScore(int NewScore)
	{
		ScoreText.SetText(FText::FromString(f"{NewScore}"));
	}

	void OnCompleted()
	{
		if(CurrentStar > 0)
			OneStar.ResetStar();
		if(CurrentStar > 1)
			TwoStar.ResetStar();
		if(CurrentStar > 2)
			ThreeStar.ResetStar();

		if(CurrentStar > 0)
			OneStar.GameComplete(0);
		if(CurrentStar > 1)
			TwoStar.GameComplete(0.5);
		if(CurrentStar > 2)
		{
			ThreeStar.GameComplete(1);
			Timer::SetTimer(this, n"AllStarsActivated", 1.5);
		}
	}

	void SetStarCount(int StarCount)
	{
		if(StarCount < CurrentStar && CurrentStar == 3)
		{
			if(CurrentStar == 3)
			{
				OneStar.StopFlashing();
				TwoStar.StopFlashing();
				ThreeStar.StopFlashing();
			}
		}

		for(int i = 1; i <= 3; i++)
		{
			if(StarCount >= i && StarCount > CurrentStar && i > CurrentStar)
			{
				if(i == 1)
					OneStar.ActivateStar();
				else if(i == 2)
					TwoStar.ActivateStar();
				else if(i == 3)
				{
					ThreeStar.ActivateStar();
					Timer::SetTimer(this, n"AllStarsActivated", 1);
				}
			}
			else if(StarCount < CurrentStar && i > StarCount && i <= CurrentStar)
			{
				if(i == 1)
					OneStar.DeactivateStar();
				else if(i == 2)
					TwoStar.DeactivateStar();
				else if(i == 3)
					ThreeStar.DeactivateStar();
			}
		}

		CurrentStar = StarCount;
	}

	UFUNCTION()
	private void AllStarsActivated()
	{
		OneStar.StartFlashing();
		TwoStar.StartFlashing();
		ThreeStar.StartFlashing();
	}
}