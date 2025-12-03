namespace TundraAudioStatics
{
	UFUNCTION(BlueprintPure)
	bool IsFairy()
	{
		UTundraPlayerShapeshiftingComponent ShapeshiftComp = UTundraPlayerShapeshiftingComponent::Get(Game::Zoe);
		return ShapeshiftComp != nullptr && ShapeshiftComp.GetCurrentShapeType() == ETundraShapeshiftShape::Small;
	}
}