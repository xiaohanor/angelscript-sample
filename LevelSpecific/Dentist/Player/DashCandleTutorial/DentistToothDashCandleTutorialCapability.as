class UDentistToothDashCandleTutorialCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(CapabilityTags::Tutorial);

	default TickGroup = EHazeTickGroup::Gameplay;

	UDentistToothDashCandleTutorialComponent DashCandleTutorialComp;
	TArray<ADentistBirthdayCandle> Candles;
	ADentistBirthdayCandle CurrentCandle;

	bool bIsShowingTutorial = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DashCandleTutorialComp = UDentistToothDashCandleTutorialComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!DashCandleTutorialComp.ShouldShowTutorial())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!DashCandleTutorialComp.ShouldShowTutorial())
			return true;
		
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Candles = TListedActors<ADentistBirthdayCandle>().Array;

		for(auto Candle : Candles)
		{
			Candle.OnBirthDayCandleLit.AddUFunction(this, n"OnCandleLit");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(bIsShowingTutorial)
		{
			Player.RemoveTutorialPromptByInstigator(this);
			bIsShowingTutorial = false;
		}

		for(auto Candle : Candles)
		{
			if(!IsValid(Candle))
				continue;

			Candle.OnBirthDayCandleLit.Unbind(this, n"OnCandleLit");
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Wait a while (this was a delay in the level BP before)
		if(ActiveDuration < 1.0)
			return;

		auto ClosestCandle = GetClosestCandle();
		if(CurrentCandle != ClosestCandle)
		{
			CurrentCandle = ClosestCandle;
			Player.RemoveTutorialPromptByInstigator(this);
			Player.ShowTutorialPromptWorldSpace(DashCandleTutorialComp.TutorialPrompt, this, CurrentCandle.ConeRotateComp, FVector(0, 0, 250), 0);
			bIsShowingTutorial = true;
		}
	}

	ADentistBirthdayCandle GetClosestCandle() const
	{
		float ClosestCandleDistance = BIG_NUMBER;
		ADentistBirthdayCandle ClosestCandle;
		for(auto Candle : Candles)
		{
			float Distance = Candle.ActorLocation.Distance(Player.ActorCenterLocation);
			if(Distance < ClosestCandleDistance)
			{
				ClosestCandleDistance = Distance;
				ClosestCandle = Candle;
			}
		}

		return ClosestCandle;
	}

	UFUNCTION()
	private void OnCandleLit(AHazePlayerCharacter InPlayer)
	{
		if(InPlayer != Player)
			return;

		DashCandleTutorialComp.bHasCompletedTutorial = true;
	}
};