struct FTundra_SimonSaysStateMonkeySuccessAnimationData
{
	int BeatDuration;
	bool bShouldDeactivateSimonSays;
}

class UTundra_SimonSaysStateMonkeySuccessAnimationCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	int BeatDuration;
	bool bShouldDeactivateSimonSays;

	int GetStateAmountOfBeats() const override
	{
		return BeatDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateMonkeySuccessAnimationData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysStateDeactivatedParams& Params) const
	{
		return Super::ShouldDeactivate(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStateMonkeySuccessAnimationData Params)
	{
		BeatDuration = Params.BeatDuration;
		bShouldDeactivateSimonSays = Params.bShouldDeactivateSimonSays;
		Manager.ChangeMainState(ETundra_SimonSaysState::MonkeySuccess);

		// No longer do thumbs up here because it will start during the player to monkey player status state!
		//Manager.MonkeyKing.AnimData.bDoThumbsUp = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);

		//Manager.MonkeyKing.AnimData.bDoThumbsUp = false;
		
		if(bShouldDeactivateSimonSays)
		{
			Manager.Deactivate();
			Manager.bDeactivatePending = false;
			Manager.OnWinSimonSays.Broadcast();

			for(AHazePlayerCharacter Player : Game::Players)
			{
				Player.DeactivateCamera(Manager.MonkeyCamera);
				Player.UnblockCapabilities(CapabilityTags::GameplayAction, Manager);
			}

			if(Manager.bDebug)
				PrintScaled("You won!!!");
		}
	}
}