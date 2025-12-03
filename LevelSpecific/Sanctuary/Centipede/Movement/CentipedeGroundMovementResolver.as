class UCentipedeGroundMovementResolver : USteppingMovementResolver
{
	EMovementImpactType GetImpactTypeFromHit(FHitResult HitResult, FVector WorldUp, FVector CustomImpactNormal) const override
	{
		// if (HitResult.bBlockingHit && HitResult.Actor != nullptr)
		// {
		// 	UCentipedeCrawlableComponent CrawlableComponent = UCentipedeCrawlableComponent::Get(HitResult.Actor);
		// 	if (CrawlableComponent != nullptr)
		// 	{
		// 		if (CrawlableComponent.bUseNormalConstraint)
		// 		{
		// 			float Dot = HitResult.ImpactNormal.DotProduct(CrawlableComponent.GetNormalConstraint());
		// 			if (Dot <= 0.5)
		// 				return EMovementImpactType::Wall;
		// 		}
		// 	}
		// }

		return Super::GetImpactTypeFromHit(HitResult, WorldUp, CustomImpactNormal);
	}

	FMovementEdge GetEdgeInformation(FMovementHitResult HitResult, FVector ForwardDirection, EMovementEdgeNormalRedirectType OverrideImpactNormalType) const override
	{
		FMovementEdge MovementEdge = Super::GetEdgeInformation(HitResult, ForwardDirection, OverrideImpactNormalType);

		// UCentipedeCrawlableComponent CrawlableComponent = UCentipedeCrawlableComponent::Get(HitResult.Actor);
		// if (CrawlableComponent != nullptr)
		// {
		// 	float Dot = HitResult.ImpactNormal.DotProduct(CrawlableComponent.GetNormalConstraint());
		// 	if (Dot <= 0.1)
		// 	{
		// 		MovementEdge.Type = EMovementEdgeType::Edge;
		// 		MovementEdge.EdgeNormal = ForwardDirection.GetSafeNormal();
		// 	}
		// }

		return MovementEdge;
	}

	FMovementEdge GetEdgeResult(FMovementHitResult HitResult) const override
	{
		// UCentipedeCrawlableComponent CrawlableComponent = UCentipedeCrawlableComponent::Get(HitResult.Actor);
		// if (CrawlableComponent != nullptr)
		// {
		// 	if (HitResult.EdgeType != EMovementEdgeType::Unset)
		// 	{
		// 		float Dot = HitResult.ImpactNormal.DotProduct(CrawlableComponent.GetNormalConstraint());
		// 		Print("dot "+ Dot, 0);
		// 		if (Dot <= 0.2)
		// 		{
		// 			Print("omfg no1", 1);
		// 			FMovementEdge EdgeResult = HitResult.EdgeResult;
		// 			EdgeResult.Type = EMovementEdgeType::Edge;
		// 			return EdgeResult;
		// 		}
		// 	}
		// }

		return Super::GetEdgeResult(HitResult);
	}
}