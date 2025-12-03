
UCLASS(Abstract)
class UWorld_Prison_Pinball_Ambience_Spot_SyncedCogWheel_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */
	UFUNCTION(BlueprintEvent)
	void OnMusicBeat()
	{

	}
	
	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UHazeAudioMusicManager::Get().OnMusicBeat.AddUFunction(this,n"OnMusicBeat");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		UHazeAudioMusicManager::Get().OnMusicBeat.UnbindObject(this);
	}
}
