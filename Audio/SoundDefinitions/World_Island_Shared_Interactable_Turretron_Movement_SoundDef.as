
UCLASS(Abstract)
class UWorld_Island_Shared_Interactable_Turretron_Movement_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Is Sidescroller"))
	bool IsSidescroller()
	{
		AHazePlayerCharacter FullscreenPlayer = SceneView::GetFullScreenPlayer();
		if(FullscreenPlayer != nullptr)
			return FullscreenPlayer.GetCurrentGameplayPerspectiveMode() == EPlayerMovementPerspectiveMode::SideScroller;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(IsSidescroller())
		{
			FVector2D _;
			float X = 0.0;
			float _Y = 0.0;
			if(Audio::GetScreenPositionRelativePanningValue(DefaultEmitter.GetEmitterLocation(), _, X, _Y))
			{
				DefaultEmitter.SetRTPC(Audio::Rtpc_SpeakerPanning_LR, X, 0.0);			
			}
		}
	}

}