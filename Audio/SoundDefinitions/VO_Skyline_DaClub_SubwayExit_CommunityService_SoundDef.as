
UCLASS(Abstract)
class UVO_Skyline_DaClub_SubwayExit_CommunityService_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnWallImpact(){}

	UFUNCTION(BlueprintEvent)
	void OnGrabbed(){}

	UFUNCTION(BlueprintEvent)
	void OnThrown(){}

	UFUNCTION(BlueprintEvent)
	void OnFlyAway(FSkylineBirdEventData SkylineBirdEventData){}

	/* END OF AUTO-GENERATED CODE */

	ASkylineWhipBirdManager Manager;
	TArray<ASkylineWhipBird> Birds;

	TPerPlayer<int> ScaredTheBirdsCounter;
	int RandomCount;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Birds = TListedActors<ASkylineWhipBird>().GetArray();

		// There are more then 1 bird.
		RandomCount = Math::RandRange(6, 15);

		for (auto Bird : Birds)
		{
			EffectEvent::LinkActorToReceiveEffectEventsFrom(HazeOwner, Bird);
		}
	}

	UFUNCTION()
	bool IncrementAndReturnIfToTrigger(AHazePlayerCharacter Player)
	{
		ScaredTheBirdsCounter[Player]++;

		if (ScaredTheBirdsCounter[Player] > RandomCount)
			return true;

		return false;
	}

}