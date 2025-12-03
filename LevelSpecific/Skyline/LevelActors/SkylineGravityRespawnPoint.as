
// Respawn point that sets the player to an altered gravity with the gravity blade after respawn
class ASkylineGravityRespawnPoint : ARespawnPoint
{
	default bCanMioUse = true;
	default bCanZoeUse = false;

	void OnRespawnTriggered(AHazePlayerCharacter Player) override
	{
		Player.OverrideGravityDirection(
			-GetActorUpVector(), Skyline::GravityProxy
		);
		
		Super::OnRespawnTriggered(Player);
	}

	UFUNCTION(BlueprintCallable)
	void TeleportPlayerWithGravityOverride(AHazePlayerCharacter Player, FInstigator Instigator)
	{
		FTransform Transform = GetPositionForPlayer(Player);

		Player.OverrideGravityDirection(
			-GetActorUpVector(), Skyline::GravityProxy
		);

		Player.TeleportActor(Transform.Location, Transform.Rotator(), Instigator);
	}
};