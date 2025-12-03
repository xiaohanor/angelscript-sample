
/**
 * Remove any sticky respawn points that the player can currently respawn at.
 */
UFUNCTION(Category = "Respawn Points", DisplayName = "Reset Player Sticky Respawn Point")
mixin void ResetStickyRespawnPoints(AHazePlayerCharacter Player)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);
	RespawnComp.ResetStickyRespawnPoints();
}

/**
 * Set a single sticky respawn point for the player to respawn at.
 */
UFUNCTION(Category = "Respawn Points", DisplayName = "Set Player Sticky Respawn Point")
mixin void SetStickyRespawnPoint(AHazePlayerCharacter Player, ARespawnPoint RespawnPoint)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);
	RespawnComp.TriggerStickyRespawnPoint(RespawnPoint);
}

/**
 * Teleport the player to a specific respawn point.
 */
UFUNCTION(Category = "Respawn Points", DisplayName = "Teleport Player to Respawn Point")
mixin void TeleportToRespawnPoint(AHazePlayerCharacter Player, ARespawnPoint RespawnPoint, FInstigator Instigator, bool bIncludeCamera = true)
{
	FTransform Transform = RespawnPoint.GetPositionForPlayer(Player);
	Player.TeleportActor(Transform.Location, Transform.Rotator(), Instigator, bIncludeCamera);
	if (bIncludeCamera && RespawnPoint.bRotatedCamera)
		Player.SnapCameraAtEndOfFrame((Transform.Rotation * FQuat(RespawnPoint.SpawnCameraRotation)).Rotator(), EHazeCameraSnapType::World);
	RespawnPoint.OnPlayerTeleportToRespawnPoint.Broadcast(Player);
}

/**
 * Override the player's active respawn point so it always goes to the specified location.
 * The override will stay until cleared with the same instigator.
 */
UFUNCTION(Category = "Respawn Points", DisplayName = "Apply Player Respawn Point Override")
mixin void ApplyRespawnPointOverrideLocation(AHazePlayerCharacter Player,
									 FInstigator Instigator, FTransform RespawnTransform,
									 USceneComponent RespawnRelativeTo = nullptr,
									 EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);

	FRespawnLocation Location;
	Location.RespawnTransform = RespawnTransform;
	Location.RespawnRelativeTo = RespawnRelativeTo;
	RespawnComp.ApplyRespawnOverrideLocation(Instigator, Location, Priority);
}

/**
 * Override the player's respawn so it queries the specified delegate to provide a respawn location
 */
mixin void ApplyRespawnPointOverrideDelegate(AHazePlayerCharacter Player,
									 FInstigator Instigator,
									 FOnRespawnOverride RespawnDelegate,
									 EInstigatePriority Priority = EInstigatePriority::Normal)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);
	RespawnComp.ApplyRespawnOverrideDelegate(Instigator, RespawnDelegate, Priority);
}

/**
 * Clear a previous override to the player's respawn point
 */
UFUNCTION(Category = "Respawn Points", DisplayName = "Clear Player Respawn Point Override")
mixin void ClearRespawnPointOverride(AHazePlayerCharacter Player, FInstigator Instigator)
{
	auto RespawnComp = UPlayerRespawnComponent::Get(Player);
	RespawnComp.ClearRespawnOverride(Instigator);
}