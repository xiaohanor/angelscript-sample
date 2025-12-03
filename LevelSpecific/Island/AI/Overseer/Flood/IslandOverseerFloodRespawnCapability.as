
class UIslandOverseerFloodRespawnCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	UIslandOverseerSettings Settings;
	UIslandOverseerPhaseComponent PhaseComp;
	UIslandOverseerFloodComponent FloodComp;
	AIslandOverseerFlood Flood;

	AHazeCharacter Character;
	TArray<AIslandOverseerFloodRespawnPoint> RespawnPoints;
	TPerPlayer<UPlayerRespawnComponent> RespawnComps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = UIslandOverseerSettings::GetSettings(Owner);
		PhaseComp = UIslandOverseerPhaseComponent::Get(Owner);
		FloodComp = UIslandOverseerFloodComponent::GetOrCreate(Owner);
		RespawnComps[Game::Mio] = UPlayerRespawnComponent::GetOrCreate(Game::Mio);
		RespawnComps[Game::Zoe] = UPlayerRespawnComponent::GetOrCreate(Game::Zoe);
		Flood = TListedActors<AIslandOverseerFlood>().GetSingle();

		TListedActors<AIslandOverseerFloodRespawnPoint> Points;
		RespawnPoints = Points.GetArray();		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::Flood)
			return false;
		if(FloodComp.bStopSettingRespawnPoints)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(PhaseComp.Phase != EIslandOverseerPhase::Flood)
			return true;
		if(FloodComp.bStopSettingRespawnPoints)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			UPlayerHealthSettings::SetEnableRespawnTimer(Player, true, this);
			UPlayerHealthSettings::SetRespawnTimer(Player, 1, this);
			UPlayerHealthSettings::SetRespawnTimerButtonMash(Player, false, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			Player.ClearSettingsByInstigator(this);

			if(Player.IsCapabilityTagBlocked(n"Respawn"))
				Player.UnblockCapabilities(n"Respawn", this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SetRespawnPoint();
	}

	void SetRespawnPoint()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!Player.HasControl())
				continue;

			AIslandOverseerFloodRespawnPoint SelectedPoint;
			for(AIslandOverseerFloodRespawnPoint Point : RespawnPoints)
			{
				FVector PointSpawnLocation = Point.GetPositionForPlayer(Player).Location;
				
				if(RespawnComps[Player].StickyRespawnPoint == Point)
					continue;
				if(!Point.IsValid())
					continue;
				if(!Point.CanPlayerUse(Player))
					continue;
				if(PointSpawnLocation.Z > Player.ActorLocation.Z + 25)
					continue;

				if(SelectedPoint == nullptr)
				{
					SelectedPoint = Point;
					continue;
				}
				
				if(PointSpawnLocation.Z > SelectedPoint.GetPositionForPlayer(Player).Location.Z)
				{
					SelectedPoint = Point;
				}
			}

			if(SelectedPoint != nullptr)
			{
				CrumbSetRespawnPoint(Player, SelectedPoint);
			}

			ARespawnPoint Point = RespawnComps[Player].StickyRespawnPoint;
			if(Point == nullptr)
				continue;

			bool Above = Point.ActorLocation.Z > Flood.ActorLocation.Z;
			if(Above && Player.IsCapabilityTagBlocked(n"Respawn"))
				CrumbSetRespawnState(Player, false);
			else if(!Above && !Player.IsCapabilityTagBlocked(n"Respawn"))
				CrumbSetRespawnState(Player, true);
		}		
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetRespawnPoint(AHazePlayerCharacter Player, AIslandOverseerFloodRespawnPoint Point)
	{
		// Set for player
		Player.SetStickyRespawnPoint(Point);

		// Set for other player
		if(Point.Pair == nullptr && Point.CanPlayerUse(Player.OtherPlayer))
		{
			Player.OtherPlayer.SetStickyRespawnPoint(Point);
		}
		else if(Point.Pair != nullptr && Point.Pair.IsValid() && Point.Pair.CanPlayerUse(Player.OtherPlayer))
		{
			Player.OtherPlayer.SetStickyRespawnPoint(Point.Pair);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetRespawnState(AHazePlayerCharacter Player, bool Block)
	{
		if(Block)
			Player.BlockCapabilities(n"Respawn", this);
		else
			Player.UnblockCapabilities(n"Respawn", this);
	}
}