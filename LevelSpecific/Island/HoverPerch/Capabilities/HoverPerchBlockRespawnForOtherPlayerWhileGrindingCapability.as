struct FHoverPerchBlockRespawnForOtherPlayerWhileGrindingActivatedParams
{
	AHazePlayerCharacter PlayerToBlock;
}

class UHoverPerchBlockRespawnForOtherPlayerWhileGrindingCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 40;

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	AHoverPerchActor PerchActor;
	AHazePlayerCharacter RespawnBlockedPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PerchActor = Cast<AHoverPerchActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FHoverPerchBlockRespawnForOtherPlayerWhileGrindingActivatedParams& Params) const
	{
		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
			return false;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return false;

		if(PerchActor.HoverPerchComp.bIsGrinding == false)
			return false;

		if(PerchActor.CurrentGrind == nullptr)
			return false;

		if(!PerchActor.CurrentGrind.bBlockOtherPlayerRespawnWhileOnGrind)
			return false;

		auto OtherPlayerPerchComp = UHoverPerchPlayerComponent::GetOrCreate(PerchActor.HoverPerchComp.PerchingPlayer.OtherPlayer);
		if(OtherPlayerPerchComp.PerchActor == nullptr)
			return false;

		if(!OtherPlayerPerchComp.PerchActor.HoverPerchComp.bIsGrinding)
			return false;

		if(!OtherPlayerPerchComp.PerchActor.CurrentGrind.bBlockOtherPlayerRespawnWhileOnGrind)
			return false;

		Params.PlayerToBlock = PerchActor.HoverPerchComp.PerchingPlayer.OtherPlayer;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PerchActor.HoverPerchComp.PerchingPlayer == nullptr)
			return true;

		if(PerchActor.HoverPerchComp.bIsDestroyed)
			return true;

		if(PerchActor.HoverPerchComp.bIsGrinding == false)
			return true;

		if(PerchActor.CurrentGrind == nullptr)
			return true;

		if(!PerchActor.CurrentGrind.bBlockOtherPlayerRespawnWhileOnGrind)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FHoverPerchBlockRespawnForOtherPlayerWhileGrindingActivatedParams Params)
	{
		RespawnBlockedPlayer = Params.PlayerToBlock;
		RespawnBlockedPlayer.BlockCapabilities(n"Respawn", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		RespawnBlockedPlayer.UnblockCapabilities(n"Respawn", this);

		if(RespawnBlockedPlayer.IsPlayerDead()
			&& RespawnBlockedPlayer.OtherPlayer.IsPlayerDead()
			&& PerchActor.CurrentGrind != nullptr
			&& PerchActor.CurrentGrind.bGameOverIfBothDie)
			UPlayerHealthComponent::Get(RespawnBlockedPlayer).TriggerGameOver();
	}
};