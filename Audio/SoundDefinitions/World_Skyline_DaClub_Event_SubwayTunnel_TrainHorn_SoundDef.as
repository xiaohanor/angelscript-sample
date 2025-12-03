
UCLASS(Abstract)
class UWorld_Skyline_DaClub_Event_SubwayTunnel_TrainHorn_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(BlueprintReadWrite)
	bool bHasPlayedHorn = false;

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return bHasPlayedHorn;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		if(!bHasPlayedHorn)
			return;

		TArray<ASkylineSubwayTrain> Trains = TListedActors<ASkylineSubwayTrain>().GetArray();

		for(auto& Train : Trains)
		{
			if(Train == HazeOwner)
				continue;

			auto SoundDefData = FSoundDefReference(GetClass());
			Train.RemoveSoundDef(SoundDefData);
		}
	}
}