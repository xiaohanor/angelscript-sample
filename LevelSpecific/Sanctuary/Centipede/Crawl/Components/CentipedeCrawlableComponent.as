class UCentipedeCrawlableComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FCentipedeCrawlConstraint> CrawlConstraints;

	bool IsLocationWithinConstraints(FVector Location)
	{
		if (CrawlConstraints.IsEmpty())
			return true;

		for (const auto& CrawlConstraint : CrawlConstraints)
		{
			FTransform WorldConstraintTransform = CrawlConstraint.GetWorldTransform(Owner);
			if (Math::IsPointInBoxWithTransform(Location, WorldConstraintTransform, CrawlConstraint.Extent))
				return true;
		}

		return false;
	}

	bool GetCurrentlyUsedConstraintForLocation(FVector Location, FCentipedeCrawlConstraint& OutCrawlConstraint)
	{
		if (CrawlConstraints.IsEmpty())
			return false;

		for (const auto& CrawlConstraint : CrawlConstraints)
		{
			FTransform WorldConstraintTransform = CrawlConstraint.GetWorldTransform(Owner);
			if (Math::IsPointInBoxWithTransform(Location, WorldConstraintTransform, CrawlConstraint.Extent))
			{
				OutCrawlConstraint = CrawlConstraint;
				return true;
			}
		}

		return false;
	}
}

class UCentipedeCrawlableComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCentipedeCrawlableComponent;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		UCentipedeCrawlableComponent CrawlableComponent = Cast<UCentipedeCrawlableComponent>(Component);
		if (CrawlableComponent == nullptr)
			return;

		for (const auto& Constraint : CrawlableComponent.CrawlConstraints)
			VisualizeConstraint(Constraint);
	}

	void VisualizeConstraint(const FCentipedeCrawlConstraint& Constraint) const
	{
		FTransform WorldTransform = Constraint.GetWorldTransform(EditingComponent.Owner);
		DrawSolidBox(this, WorldTransform.Location, WorldTransform.Rotation, Constraint.Extent, FLinearColor::LucBlue, 0.1);
	}
#endif
}