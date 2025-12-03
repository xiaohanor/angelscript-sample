class UIslandOverseerRollerBlockRespawnPointCapability : UHazeCapability
{
	UIslandOverseerRollerComponent RollerComp;
	UIslandOverseerRollerSweepComponent SweepComp;
	TPerPlayer<UPlayerRespawnComponent> RespawnComps;
	TPerPlayer<ARespawnPoint> RollerRespawnPoints;
	TPerPlayer<ARespawnPoint> OriginalRespawnPoints;
	UHazeSplineComponent RollerSpline;
	TArray<FVector> RespawnLocations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		RollerComp = UIslandOverseerRollerComponent::GetOrCreate(Owner);
		SweepComp = UIslandOverseerRollerSweepComponent::GetOrCreate(Owner);

		RollerSpline = TListedActors<AIslandOverseerRollerSweepSpline>().GetSingle().Spline;

		RespawnLocations.Add(RollerSpline.GetWorldLocationAtSplineDistance(0));
		RespawnLocations.Add(RollerSpline.GetWorldLocationAtSplineDistance(RollerSpline.SplineLength));

		ARespawnPoint MioPoint = SpawnActor(ARespawnPoint, Level = Owner.Level);
		MioPoint.MakeNetworked(this, Game::Mio, n"RollerSweepRespawnPoint");
		MioPoint.ActorLocation = RespawnLocations[0];
		ARespawnPoint ZoePoint = SpawnActor(ARespawnPoint, Level = Owner.Level);
		ZoePoint.MakeNetworked(this, Game::Zoe, n"RollerSweepRespawnPoint");
		ZoePoint.ActorLocation = RespawnLocations[1];

		RollerRespawnPoints[Game::Mio] = MioPoint;
		RollerRespawnPoints[Game::Zoe] = ZoePoint;
		for(AHazePlayerCharacter Player : Game::Players)
			RespawnComps[Player] = UPlayerRespawnComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!RollerComp.bDetached)
			return false;
		if(RollerComp.bDestroyed)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!RollerComp.bDetached)
			return true;
		if(RollerComp.bDestroyed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			OriginalRespawnPoints[Player] = RespawnComps[Player].StickyRespawnPoint;
			Player.SetStickyRespawnPoint(RollerRespawnPoints[Player]);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			ARespawnPoint Point = OriginalRespawnPoints[Player];
			if(Point != nullptr)
				Player.SetStickyRespawnPoint(Point);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			ARespawnPoint RespawnPoint = RollerRespawnPoints[Player];
			FVector LeftLocation = RespawnLocations[0];
			FVector RightLocation = RespawnLocations[1];

			if(LeftLocation.Dist2D(Owner.ActorLocation) < 250)
				RespawnPoint.ActorLocation = RightLocation;
			else if(RightLocation.Dist2D(Owner.ActorLocation) < 250)
				RespawnPoint.ActorLocation = LeftLocation;
			else if(SweepComp.bReverse)
				RespawnPoint.ActorLocation = RightLocation;
			else
				RespawnPoint.ActorLocation = LeftLocation;
		}
	}
}