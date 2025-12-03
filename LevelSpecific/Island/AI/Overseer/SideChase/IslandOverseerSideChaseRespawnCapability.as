
class UIslandOverseerSideChaseRespawnCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandOverseerSettings Settings;
	UIslandOverseerPhaseComponent PhaseComp;

	FBasicAIAnimationActionDurations Durations;
	AHazeCharacter Character;

	TPerPlayer<AIslandOverseerSideChaseRespawnPoint> RespawnPoints;
	AIslandOverseerTowardsChasePoint TowardsChasePoint;
	UHazeSplineComponent Spline;
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
		AIslandOverseerSideChaseRespawnPoint MioPoint = SpawnActor(AIslandOverseerSideChaseRespawnPoint, Level = Owner.Level);
		MioPoint.MakeNetworked(this, Game::Mio, n"SideChaseRespawnPoint");
		AIslandOverseerSideChaseRespawnPoint ZoePoint = SpawnActor(AIslandOverseerSideChaseRespawnPoint, Level = Owner.Level);
		ZoePoint.MakeNetworked(this, Game::Zoe, n"SideChaseRespawnPoint");
		RespawnPoints[Game::Mio] = MioPoint;
		RespawnPoints[Game::Zoe] = ZoePoint;
		TowardsChasePoint = TListedActors<AIslandOverseerTowardsChasePoint>()[0];

		AIslandOverseerSideChaseMoveSplineContainer Container = TListedActors<AIslandOverseerSideChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == EIslandOverseerPhase::SideChase)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase == EIslandOverseerPhase::SideChase)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Respawn(DeltaTime);
	}

	void Respawn(float DeltaTime)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			AIslandOverseerSideChaseRespawnPoint Point = RespawnPoints[Player];
			FVector ForwardLocation = Owner.ActorLocation + (Owner.ActorForwardVector * Settings.SideChaseRespawnDistance);
			Point.ActorLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(ForwardLocation);

			// Do not respawn further away than the ending
			if(Owner.ActorForwardVector.DotProduct(TowardsChasePoint.ActorLocation - Point.ActorLocation) < 0)
				Point.ActorLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(TowardsChasePoint.ActorLocation);

			TListedActors<AIslandOverseerWallBomb> Bombs;
			FVector ClosestBombLocation;
			bool bHasClosest = false;
			for(AIslandOverseerWallBomb Bomb : Bombs)
			{
				if(!Bomb.ProjectileComp.bIsLaunched)
					continue;
				if(!bHasClosest || Bomb.GetDistanceTo(Owner) < ClosestBombLocation.Distance(Owner.ActorLocation))
				{
					bHasClosest = true;
					ClosestBombLocation = Bomb.DeployWallLocation;
				}
			}

			if(bHasClosest)
			{
				if(Owner.ActorForwardVector.DotProduct(ClosestBombLocation - Point.ActorLocation) < 0)
					Point.ActorLocation = Spline.GetClosestSplineWorldLocationToWorldLocation(ClosestBombLocation - Owner.ActorForwardVector * 150);
			}

			Player.SetStickyRespawnPoint(Point);
		}
	}
}