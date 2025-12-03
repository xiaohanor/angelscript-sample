
UCLASS(Abstract)
class UVO_SideInteract_Skyline_Scanner_CleanerBot_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void Respawn_RespawnFinished(){}

	UFUNCTION(BlueprintEvent)
	void SkylineCleanerBot_OnFireAtPlayer(FSkylineCleanerBotEventData SkylineCleanerBotEventData){}

	UFUNCTION(BlueprintEvent)
	void SkylineCleanerBot_OnPerchStarted(FSkylineCleanerBotEventData SkylineCleanerBotEventData){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	ASkylineCleanerBot CleanerBot;
}