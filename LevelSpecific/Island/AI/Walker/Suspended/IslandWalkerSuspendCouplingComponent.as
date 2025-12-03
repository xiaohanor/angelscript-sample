class UIslandWalkerSuspendCouplingComponent : USceneComponent
{
	FVector CableRailOffset;
	EHazePlayer DestroyedByPlayer;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		FVector Offset = Owner.ActorTransform.TransformVectorNoScale(CableRailOffset);
		Debug::DrawDebugSphere(WorldLocation + Offset, 20.0, 4, FLinearColor::LucBlue, 5.0);
		Debug::DrawDebugLine(WorldLocation, WorldLocation + Offset, FLinearColor::LucBlue, 1.0);
	}
#endif
}
