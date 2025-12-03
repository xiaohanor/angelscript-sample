class USkylineGeckoKeepPerchersInViewFocusGetter : UHazeCameraWeightedFocusTargetCustomGetter
{
	USceneComponent GetFocusComponent() const override
	{
		return nullptr;
	}

	FVector GetFocusLocation() const override
	{
		UHazeTeam GeckoTeam = HazeTeam::GetTeam(SkylineGeckoTags::SkylineGeckoTeam);

		FVector TargetLoc = (Game::Zoe.ActorLocation + Game::Mio.ActorLocation) * 0.5;
		if (GeckoTeam != nullptr)
		{
			for (AHazeActor Gecko : GeckoTeam.GetMembers())
			{
				// Use all geckos for now
				if (TargetLoc.Z < Gecko.ActorLocation.Z)
					TargetLoc.Z = Gecko.ActorLocation.Z;
			}
		}
		return TargetLoc;
	}
}
