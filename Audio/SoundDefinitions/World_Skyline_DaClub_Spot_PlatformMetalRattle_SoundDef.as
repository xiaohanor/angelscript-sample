
UCLASS(Abstract)
class UWorld_Skyline_DaClub_Spot_PlatformMetalRattle_SoundDef : USpot_Tracking_SoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		auto MusicManager = UHazeAudioMusicManager::Get();
		MusicManager.OnMainMusicBeat().AddUFunction(this, n"OnMusicBeat");
	}

	UFUNCTION(BlueprintEvent)
	void OnMusicBeat()
	{

	}

}