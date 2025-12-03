namespace Sketchbook
{
	UFUNCTION(BlueprintCallable)
	void PostSketchbookEnterBoat(AHazePlayerCharacter Player, AActor ShipHull, FHazePlaySlotAnimationParams Anim)
	{
		Player.PlaySlotAnimation(Anim);
		Player.AttachToActor(ShipHull, AttachmentRule = EAttachmentRule::KeepWorld);
	}
}