class USummitTeleportTraversalMethod : UTraversalMethod
{
	default ScenepointClass = UTeleportTraversalScenepoint;
	default VisualizationColor = FLinearColor::Gray;

	bool CanTraverse(UScenepointComponent From, UScenepointComponent To) override
	{
		if (!IsInRange(From, To))
			return false;
		if (!From.IsA(UTeleportTraversalScenepoint))
			return false;
		return true;
	}

	void AddTraversalPath(UScenepointComponent From, UScenepointComponent To) override
	{
		Super::AddTraversalPath(From, To);

		UTeleportTraversalScenepoint TeleportFrom = Cast<UTeleportTraversalScenepoint>(From);
		if (TeleportFrom == nullptr)
			return;
		TeleportFrom.AddDestination(To.WorldLocation, To.Owner, To.Radius);
	}
}
