namespace IslandShieldotron
{
	bool HasAnyPlayerClaimedToken(const FName& Token, const UObject Claimant)
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			UGentlemanComponent CurrentGentlemanComp = UGentlemanComponent::Get(Player);
			if (CurrentGentlemanComp == nullptr)
				continue;
			if (!CurrentGentlemanComp.CanClaimToken(Token, Claimant))
				return true;
		}
		return false;
	}

	bool HasClearMortarTrajectory(FVector LaunchLocation, FVector TargetLocation, FVector LaunchVelocity, float LandingSteepness)
	{
		FVector LandTangent = GetMortarLandTangent(LaunchLocation, TargetLocation, LandingSteepness);
						
		FHitResult Hit;
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
		Trace.UseLine();
		
		// Arbitrarily trace from start to 1.0 Alpha in steps of 0.1
		FVector PrevLoc = LaunchLocation;
		for (int i = 1; i <= 5; ++i)
		{
			float Alpha = 0.1 * i;
			FVector NewLoc = BezierCurve::GetLocation_2CP(
				LaunchLocation,
				LaunchLocation + LaunchVelocity,
				TargetLocation - LandTangent,
				TargetLocation,
				Alpha);

#if EDITOR	
		bool bDebugDraw = false;
		if (bDebugDraw)
		{
			Debug::DrawDebugLine(PrevLoc, NewLoc, FLinearColor::Red, Duration = 5.0);
		}
#endif	
			Hit = Trace.QueryTraceSingle(PrevLoc, NewLoc);
			if (Hit.bBlockingHit)
				return false;

			PrevLoc = NewLoc;
		}

		return true;
	}

	FVector GetMortarLandTangent(FVector LaunchLocation, FVector TargetLocation, float LandingSteepness)
	{
		FVector ToTarget = TargetLocation - LaunchLocation;
		FVector LandDir = ToTarget - FVector::UpVector * LandingSteepness;
		return LandDir;
	}

	namespace Team
	{
		void SetPlayersLastKnownArea(AHazeActor Player, ATraversalAreaActorBase Area)
		{
			AHazePlayerCharacter TargetPlayer = Cast<AHazePlayerCharacter>(Player);
			UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
			UHazeTeam Team = Manager.GetTeam(IslandShieldotronTags::IslandShieldotronTeam);
			Cast<UIslandShieldotronTeam>(Team).SetPlayersLastKnownArea(TargetPlayer, Area);
		}

		TArray<ATraversalAreaActorBase> GetPlayersLastKnownAreas()
		{
			UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
			UHazeTeam Team = Manager.GetTeam(IslandShieldotronTags::IslandShieldotronTeam);
			return Cast<UIslandShieldotronTeam>(Team).GetPlayersLastKnownAreas();
		}
		
		FPlayerTraversalAreaInfo GetPlayerLastKnownAreaInfo(AHazeActor Player)
		{
			AHazePlayerCharacter TargetPlayer = Cast<AHazePlayerCharacter>(Player);
			UHazeTeamManager Manager = Game::GetSingleton(UHazeTeamManager);
			UHazeTeam Team = Manager.GetTeam(IslandShieldotronTags::IslandShieldotronTeam);
			return Cast<UIslandShieldotronTeam>(Team).GetPlayersLastKnownAreaInfo(TargetPlayer);
		}
	}
}