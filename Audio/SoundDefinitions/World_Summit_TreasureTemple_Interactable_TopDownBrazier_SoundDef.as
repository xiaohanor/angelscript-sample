
UCLASS(Abstract)
class UWorld_Summit_TreasureTemple_Interactable_TopDownBrazier_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnWingsStartedMovingBack(){}

	UFUNCTION(BlueprintEvent)
	void OnWingsStartedMovingOut(){}

	UFUNCTION(BlueprintEvent)
	void OnFinished(){}

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		FVector2D PreviousScreenPosition;
		float PanningRTPC = 0.0;
		float _Y;

		Audio::GetScreenPositionRelativePanningValue(HazeOwner.ActorLocation, PreviousScreenPosition, PanningRTPC, _Y);
		DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, PanningRTPC, 0.0);
	}

}