// class UTundraPlayerShapeshiftingNetworkBlockCapability : UHazePlayerCapability
// {
// 	// This capability exists so we don't get an ensure if we shapeshift the frame
// 	// after exiting a cutscene, the remote side might still be in the cutscene
// 	// when the morph happens which will lead to an ensure because we cannot request
// 	// features during cutscenes.
// 	default NetworkMode = EHazeCapabilityNetworkMode::ImmediateNetFunction;

// 	default TickGroup = EHazeTickGroup::PreFrameNetworking;

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!Network::IsGameNetworked())
// 			return false;

// 		if(Player.OtherPlayer.Mesh.CanRequestOverrideFeature())
// 			return false;

// 		return true;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(!Network::IsGameNetworked())
// 			return true;

// 		if(Player.OtherPlayer.Mesh.CanRequestOverrideFeature())
// 			return true;

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		Player.OtherPlayer.BlockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		Player.OtherPlayer.UnblockCapabilities(TundraShapeshiftingTags::ShapeshiftingInput, this);
// 	}
// }