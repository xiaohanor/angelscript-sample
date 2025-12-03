
UCLASS(Abstract)
class UGameplay_Ability_Meltdown_SplitCrossing_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	/* END OF AUTO-GENERATED CODE */

	ASplitTraversalManager SplitManager;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		SplitManager = ASplitTraversalManager::GetSplitTraversalManager();
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Distance To Split"))
	float GetDistanceToSplit()
	{
		FVector2D ScreenPosition;
		SceneView::ProjectWorldToScreenPosition(Game::GetMio(), PlayerOwner.ActorLocation, ScreenPosition);
		return ScreenPosition.X - SplitManager.SplitPosition;
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Distance To Player"))
	float GetDistanceToPlayerView()
	{	
		return Game::Mio.ViewLocation.Distance(PlayerOwner.ActorLocation);
	}

	UFUNCTION(BlueprintPure, Meta = (CompactNodeTitle = "Panning Value"))
	float GetPanningValue()
	{
		const float MappedPanning = Math::GetMappedRangeValueClamped(FVector2D(0.0, 1.0), FVector2D(-1.0, 1.0), SplitManager.SplitPosition);
		return MappedPanning * Audio::GetPanningRuleMultiplier();
	}
}