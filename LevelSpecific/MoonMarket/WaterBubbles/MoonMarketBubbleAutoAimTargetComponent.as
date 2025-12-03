class UMoonMarketBubbleAutoAimTargetComponent : UAutoAimTargetComponent
{
	default TargetableCategory = n"MoonMarketBubble";
	default MaximumDistance = 1000;

	bool CheckTargetable(FTargetableQuery& Query) const override
	{
		AMoonMarketWaterBubble Bubble = Cast<AMoonMarketWaterBubble>(Owner);
		
		if(UMoonMarketPlayerBubbleComponent::Get(Query.Player).CurrentBubble == Bubble)
			return false;

		return Super::CheckTargetable(Query);;
	}
};