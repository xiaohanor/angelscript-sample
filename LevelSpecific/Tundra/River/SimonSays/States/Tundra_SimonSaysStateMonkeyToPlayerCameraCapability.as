struct FTundra_SimonSaysStateMonkeyToPlayerCameraData
{
	int BeatDuration;
}

class UTundra_SimonSaysStateMonkeyToPlayerCameraCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	int BeatDuration;

	int GetStateAmountOfBeats() const override
	{
		return BeatDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStateMonkeyToPlayerCameraData& Params) const
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
	void OnActivated(FTundra_SimonSaysStateMonkeyToPlayerCameraData Params)
	{
		BeatDuration = Params.BeatDuration;
		Manager.ChangeMainState(ETundra_SimonSaysState::CameraToPlayer);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.BlockCapabilities(n"Respawn", Manager);
			Player.DeactivateCamera(Manager.MonkeyCamera, GetCameraBlendDuration());
			Player.UnblockCapabilities(CapabilityTags::GameplayAction, Manager);
		}

		for(auto AnimComp : Manager.AnimComps)
		{
			AnimComp.Value.AnimData.bIsSuccess = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);
	}

	float GetCameraBlendDuration() const
	{
		return GetStateTotalTime() - Manager.GetCurrentStateActiveDuration();
	}
}