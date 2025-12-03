struct FTundra_SimonSaysStateDeactivateData
{
	
}

class UTundra_SimonSaysStateDeactivateCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	FTundra_SimonSaysStateDeactivateData CurrentData;

	int GetStateAmountOfBeats() const override
	{
		return 0;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateDeactivateData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysStateDeactivatedParams& Params) const
	{
		Params.StateDuration = 0;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStateDeactivateData Params)
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

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);
	}
}