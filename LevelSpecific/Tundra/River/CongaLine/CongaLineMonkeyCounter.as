class UCongaLineMonkeyCounter : UActorComponent
{
	UPROPERTY(BlueprintReadOnly)
	int CurrentStage = 0;

	UPROPERTY(BlueprintReadOnly)
	const int MaxNumStages = 1;

	UPROPERTY(BlueprintReadOnly)
	const int MonkeysPerStage = 40;

	UPROPERTY(BlueprintReadOnly)
	int MioMonkeyAmount = 0;

	UPROPERTY(BlueprintReadOnly)
	int ZoeMonkeyAmount = 0;

	bool bHasTriggeredOnce = false;


	UFUNCTION(BlueprintPure)
	int GetTotalMonkeyAmount() const
	{
		return MioMonkeyAmount + ZoeMonkeyAmount;
	}

	bool AllMonkeysCollected() const
	{
		return GetTotalMonkeyAmount() == MonkeysPerStage * MaxNumStages;
	}

	void SetMonkeyAmount(int NewMonkeyAmount, EMonkeyColorCode ColorCode, bool GainedMonkey)
	{
		int CurrentTotalMonkeys = MioMonkeyAmount + ZoeMonkeyAmount;

		if(ColorCode == EMonkeyColorCode::Mio)
			MioMonkeyAmount = NewMonkeyAmount;
		else 
			ZoeMonkeyAmount = NewMonkeyAmount;

		int NewTotalMonkeys = MioMonkeyAmount + ZoeMonkeyAmount;


		int MaxMonkeys = MonkeysPerStage * MaxNumStages;

		if(CurrentTotalMonkeys < MaxMonkeys && NewTotalMonkeys >= MaxMonkeys)
		{
			CongaLine::GetManager().OnMonkeyBarFilledEvent.Broadcast();
			bHasTriggeredOnce = true;
		}
	
		if(CurrentTotalMonkeys == MaxMonkeys && NewTotalMonkeys < MaxMonkeys)
			CongaLine::GetManager().OnMonkeyBarLostEvent.Broadcast();
		

		if(GainedMonkey)
		{
			CongaLine::GetManager().OnMonkeyGainedEvent.Broadcast(NewTotalMonkeys);
		}
		else
		{
			CongaLine::GetManager().OnMonkeyLostEvent.Broadcast(NewTotalMonkeys);
		}

		CongaLine::GetManager().OnMonkeyAmountChangedEvent.Broadcast(NewTotalMonkeys);
			
		CurrentStage = Math::IntegerDivisionTrunc(NewMonkeyAmount, MonkeysPerStage);
		CongaLine::GetManager().SetStage(CurrentStage);
	}
};