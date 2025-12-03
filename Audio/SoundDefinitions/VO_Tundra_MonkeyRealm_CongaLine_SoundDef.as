
UCLASS(Abstract)
class UVO_Tundra_MonkeyRealm_CongaLine_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void LowerWall(FCongaLowerWallEventParams CongaLowerWallEventParams){}

	UFUNCTION(BlueprintEvent)
	void RowUnlit(){}

	UFUNCTION(BlueprintEvent)
	void RowLit(){}

	UFUNCTION(BlueprintEvent)
	void TileUnlit(FCongaTileLightUpEventParams CongaTileLightUpEventParams){}

	UFUNCTION(BlueprintEvent)
	void TileLightUp(FCongaTileLightUpEventParams CongaTileLightUpEventParams){}

	UFUNCTION(BlueprintEvent)
	void OnDancersLost(FCongaLinePlayerLostDancersEventData CongaLinePlayerLostDancersEventData){}

	UFUNCTION(BlueprintEvent)
	void OnDancerGained(FCongaLineDancerGainedEventData CongaLineDancerGainedEventData){}

	/* END OF AUTO-GENERATED CODE */

UFUNCTION(BlueprintOverride)
    void OnActivated()
    {
        UHazeAudioMusicManager::Get().OnMusicBar.AddUFunction(this,n"OnMusicBar");
    }

UFUNCTION(BlueprintEvent)
    void OnMusicBar()
    {

    }
}