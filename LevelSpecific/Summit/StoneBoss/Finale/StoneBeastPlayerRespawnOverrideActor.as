UCLASS(NotBlueprintable)
class AStoneBeastPlayerRespawnOverrideActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	float BackwardsOffset = 250.0;

	bool bHasAppliedRespawnOverride;

	UFUNCTION()
	void OverrideRespawnsWithPlayerLocations(float NewBackwardsOffset = 200.0)
	{
		if (bHasAppliedRespawnOverride)
			return;

		bHasAppliedRespawnOverride = true;
		BackwardsOffset = NewBackwardsOffset;
		Game::Mio.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"), EInstigatePriority::High);
		Game::Zoe.ApplyRespawnPointOverrideDelegate(this, FOnRespawnOverride(this, n"HandleRespawn"), EInstigatePriority::High);
	}

	UFUNCTION()
	void ClearRespawnOverrides()
	{
		if (!bHasAppliedRespawnOverride)
			return;

		bHasAppliedRespawnOverride = false;
		Game::Mio.ClearRespawnPointOverride(this);
		Game::Zoe.ClearRespawnPointOverride(this);
	}

	UFUNCTION()
	private bool HandleRespawn(AHazePlayerCharacter Player, FRespawnLocation& OutLocation)
	{
		FTransform RespawnTransform = Player.OtherPlayer.RootComponent.WorldTransform;
		Debug::DrawDebugSphere(RespawnTransform.Location, 300.0, 12, FLinearColor::Green, 5.0, 10.0);
		RespawnTransform.SetLocation(RespawnTransform.Location + FVector(1,0,0) * BackwardsOffset);
		OutLocation.RespawnTransform = RespawnTransform;
		// OutLocation.RespawnRelativeTo = RespawnRelativeActor.RootComponent;
		return true;
	}
};