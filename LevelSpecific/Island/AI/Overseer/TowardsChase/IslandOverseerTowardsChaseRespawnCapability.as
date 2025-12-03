
class UIslandOverseerTowardsChaseRespawnCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandOverseerSettings Settings;
	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerTowardsChaseComponent TowardsChaseComp;

	AHazeCharacter Character;
	TPerPlayer<AIslandOverseerSideChaseRespawnPoint> RespawnPoints;
	UHazeSplineComponent Spline;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
		TowardsChaseComp = UIslandOverseerTowardsChaseComponent::Get(Owner);
		RespawnPoints[Game::Mio] = SpawnActor(AIslandOverseerSideChaseRespawnPoint, Level = Owner.Level);
		RespawnPoints[Game::Mio].MakeNetworked(this, Game::Mio, n"TowardChaseRespawnPoint");
		RespawnPoints[Game::Zoe] = SpawnActor(AIslandOverseerSideChaseRespawnPoint, Level = Owner.Level);
		RespawnPoints[Game::Zoe].MakeNetworked(this, Game::Zoe, n"TowardChaseRespawnPoint");

		AIslandOverseerTowardsChaseMoveSplineContainer Container = TListedActors<AIslandOverseerTowardsChaseMoveSplineContainer>()[0];
		TArray<AActor> Actors;
		Container.GetAttachedActors(Actors);
		Spline = Cast<ASplineActor>(Actors[0]).Spline;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase == EIslandOverseerPhase::TowardsChase)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase == EIslandOverseerPhase::TowardsChase)
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
			AIslandOverseerSideChaseRespawnPoint Point = RespawnPoints[Player];

			FVector Location;
			float Distance = TowardsChaseComp.SplineDistance + Settings.TowardsChaseRespawnDistance;

			// If we try to spawn beyond end of spline, we used forward vector instead
			if(Distance > Spline.SplineLength)
				Location = Owner.ActorLocation + Owner.ActorForwardVector * Settings.TowardsChaseRespawnDistance;
			else
				Location = Spline.GetWorldLocationAtSplineDistance(TowardsChaseComp.SplineDistance + Settings.TowardsChaseRespawnDistance);

			Point.ActorLocation = Location;
			Player.SetStickyRespawnPoint(Point);
		}
	}
}