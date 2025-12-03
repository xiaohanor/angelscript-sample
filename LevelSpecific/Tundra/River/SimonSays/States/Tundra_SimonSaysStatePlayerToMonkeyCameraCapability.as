struct FTundra_SimonSaysStatePlayerToMonkeyCameraData
{
	int BeatDuration;
	int StageToSetLocationTo;
	float CameraBlendTime;
}

class UTundra_SimonSaysStatePlayerToMonkeyCameraCapability : UTundra_SimonSaysStateBaseCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	int BeatDuration;
	int StageIndexToSetLocationOf;

	int GetStateAmountOfBeats() const override
	{
		return BeatDuration;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FTundra_SimonSaysStatePlayerToMonkeyCameraData& Params) const
	{
		if (StateComp.StateQueue.Start(this, Params))
		{
			Params.CameraBlendTime = GetCameraBlendDuration(Params.BeatDuration);
			return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FTundra_SimonSaysStateDeactivatedParams& Params) const
	{
		return Super::ShouldDeactivate(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FTundra_SimonSaysStatePlayerToMonkeyCameraData Params)
	{
		UTundra_SimonSaysManagerEffectHandler::Trigger_OnCameraStartMovingToMonkeyKing(Manager);

		BeatDuration = Params.BeatDuration;
		StageIndexToSetLocationOf = Params.StageToSetLocationTo;
		Manager.ChangeMainState(ETundra_SimonSaysState::CameraToMonkey);

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.ActivateCamera(Manager.MonkeyCamera, Params.CameraBlendTime, Manager, EHazeCameraPriority::VeryHigh);
			Player.BlockCapabilities(CapabilityTags::GameplayAction, Manager);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FTundra_SimonSaysStateDeactivatedParams Params)
	{
		Super::OnDeactivated(Params);
		StateComp.StateQueue.Finish(this);

		for(auto AnimComp : Manager.AnimComps)
		{
			AnimComp.Value.AnimData.bIsFail = false;
		}

		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.UnblockCapabilities(n"Respawn", Manager);
			ACongaDanceFloorTile Tile = Manager.GetTileForPlayer(Player, StageIndexToSetLocationOf, 0);
			Player.ActorLocation = Tile.SimonSaysTargetable.WorldLocation;
			UTundra_SimonSaysPlayerComponent::GetOrCreate(Player).CurrentPerchedTile = Tile;
		}
	}

	float GetCameraBlendDuration(float In_BeatDuration) const
	{
		return (Manager.GetRealTimeBetweenBeats() * In_BeatDuration) - Manager.GetCurrentStateActiveDuration();
	}
}