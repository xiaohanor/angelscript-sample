class UIslandWalkerFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		AIslandWalkerHead WalkerHead = IslandWalker::GetWalkerHead();

		if (WalkerHead != nullptr)
			return WalkerHead.ActorLocation;

		return Game::Zoe.ActorLocation;
	}
}

namespace IslandWalker
{
	// Get the example listed actor in the level
	UFUNCTION()
	AIslandWalkerHead GetWalkerHead()
	{
		return TListedActors<AIslandWalkerHead>().GetSingle();
	}

}