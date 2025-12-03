
UCLASS(Abstract)
class UWorld_Sketchbook_Shared_Gadget_Bow_Arrow_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Hit(FSketchbookArrowHitEventData HitData){}

	UFUNCTION(BlueprintEvent)
	void Launch(FSketchbookArrowLaunchEventData LaunchData){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (bFirstActivation)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		// The arrows can in certain places travel on forever, if so disable them when getting 
		// to far below the players.
		for (auto Player: Game::Players)
		{
			auto Distance = Player.ActorLocation.Z  - HazeOwner.ActorLocation.Z;

			if (Distance < 3000)
			{
				return false;
			}

			return true;
		}

		return false;
	}
}