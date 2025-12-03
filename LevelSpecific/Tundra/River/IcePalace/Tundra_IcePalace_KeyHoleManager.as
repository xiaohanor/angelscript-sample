event void FOnKeyPuzzleComplete();

class ATundra_IcePalace_KeyHoleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_IcePalace_KeySymbol> KeySymbols;

	UPROPERTY(EditInstanceOnly)
	TArray<ATundra_IcePalace_RotatingKeyPin> RotatingKeyPins;

	UPROPERTY(EditInstanceOnly)
	ATundra_IcePalace_InsideLockLever Lever;

	bool bRaisingPins = false;
	bool bComplete = false;
	float RaisePinTimer = 0;
	int RaisePinIndex = 0;
	int NumberOfSymbolsPunchedCorrectly = 0;
	
	TArray<bool> PinsRotatedCorrectly;

	UPROPERTY()
	FOnKeyPuzzleComplete OnKeyPuzzleComplete;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Mio);

		Lever.OnLeverReset.AddUFunction(this, n"OnLeverReset");
		
		for(auto Pin : RotatingKeyPins)
		{
			Pin.OnRotationComplete.AddUFunction(this, n"OnKeyPinRotationComplete");
		}

		for(auto Symbol : KeySymbols)
		{
			Symbol.OnKeySymbolMoved.AddUFunction(this, n"OnKeySymbolMoved");
		}

		//Audio
		for (auto KeySymbol : KeySymbols)
		{
			EffectEvent::LinkActorToReceiveEffectEventsFrom(this, KeySymbol);
		}

		for (auto KeyPin : RotatingKeyPins)
		{
			EffectEvent::LinkActorToReceiveEffectEventsFrom(this, KeyPin);
		}
	
		EffectEvent::LinkActorToReceiveEffectEventsFrom(this, Lever);

		PinsRotatedCorrectly.Add(false);
		PinsRotatedCorrectly.Add(false);
		PinsRotatedCorrectly.Add(false);
		PinsRotatedCorrectly.Add(false);
	}

	UFUNCTION()
	private void OnKeyPinRotationComplete(bool bCorrectRotation, int StartingSymbolIndex)
	{
		PinsRotatedCorrectly[StartingSymbolIndex] = bCorrectRotation;


		bool bShouldPlayVO = true;
		for(auto Correct : PinsRotatedCorrectly)
		{
			if(!Correct)
			{
				bShouldPlayVO = false;
			}
		}

		if(bShouldPlayVO)
		{
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnPinsInRightOrderNoSymbolsPunchedIn(this);
		}
	}

	UFUNCTION()
	private void OnLeverReset()
	{
		bool bAlmostCorrectOrder = true;
		for(auto Pin : RotatingKeyPins)
		{
			if(!Pin.bAlmostCorrectOrder)
			{
				bAlmostCorrectOrder = false;
				break;
			}
		}
		
		//Many players try to match the keypin order to the order of which the symbols are presented on the door. It's not correct, but we want to acknowledge that with VO.
		if(bAlmostCorrectOrder)
		{
			FKeyHoleLeverParams Params;
			Params.Lever = Lever;
			UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnLeverStoppedWithStartingKeyPinOrder(this, Params);
		}

		NumberOfSymbolsPunchedCorrectly = 0;
	}

	UFUNCTION()
	private void OnKeySymbolMoved(bool bCorrectPos, bool bWasPunched)
	{
		if(!HasControl())
			return;

		if(bCorrectPos)
			NumberOfSymbolsPunchedCorrectly++;

		if(NumberOfSymbolsPunchedCorrectly >= 4)
		{
			Timer::SetTimer(this, n"CrumbRaisePins", 0.5);
			Lever.CrumbStopLever();
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// Just animating the pins a bit when the puzzle is complete.
		if(bRaisingPins)
		{
			RaisePinTimer -= DeltaSeconds;
			if(RaisePinTimer <= 0)
			{
				RotatingKeyPins[RaisePinIndex].SetLockPinCompleteState();
				RaisePinTimer = 0.1;
				RaisePinIndex++;
				
				if(!RotatingKeyPins.IsValidIndex(RaisePinIndex))
				{
					bRaisingPins = false;
					bComplete = true;
					Timer::SetTimer(this, n"OpenDoor", 0.75);
				}
			}
		}
	}

	UFUNCTION()
	void RaisePins()
	{
		CrumbRaisePins();
	}

	UFUNCTION(CrumbFunction)
	void CrumbRaisePins()
	{
		if(bRaisingPins)
			return;

		if(bComplete)
			return;

		for(auto Pin : RotatingKeyPins)
			Pin.OneShotInteractionComp.Disable(this);
			//Pin.InteractionComp.Disable(this);

		bRaisingPins = true;
		Game::Zoe.BlockCapabilities(n"TundraKeyPin", this);
		UTundra_IcePalace_KeyHoleEffectHandler::Trigger_OnCrumbRaisePins(this);
	}

	UFUNCTION()
	void OpenDoor()
	{
		Game::Zoe.UnlockPlayerMovementFromSpline(this);
		Game::Zoe.TundraShapeshiftingClearSettingsForShape(ETundraShapeshiftActiveShape::Small, this);
		OnKeyPuzzleComplete.Broadcast();
	}
}