class AIslandOverseerFloodRespawnPoint : ARespawnPoint
{
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	default ListedComp.bDelistWhileActorDisabled = false;

	UPROPERTY(EditInstanceOnly)
	AIslandOverseerFloodRespawnPoint Pair;

	UPROPERTY(EditInstanceOnly)
	AIslandOverseerFloodRespawnPoint Invalidating;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Super::ConstructionScript();
		if(Pair != nullptr)
			Pair.Pair = this;
	}

	bool IsValid()
	{
		if(IsActorDisabled())
			return false;

		if(Invalidating != nullptr)
		{
			// Return false when this point passes Invalidating point
			if(ActorLocation.Z > Invalidating.ActorLocation.Z)
				return false;
		}

		return true;
	}

	bool CanPlayerUse(AHazePlayerCharacter Player)
	{
		if(Player == Game::Mio && !bCanMioUse)
			return false;
		if(Player == Game::Zoe && !bCanZoeUse)
			return false;

		UPlayerRespawnComponent RespawnComp = UPlayerRespawnComponent::GetOrCreate(Player);
		ARespawnPoint CurrentPoint = RespawnComp.StickyRespawnPoint;
		if(CurrentPoint != nullptr && GetPositionForPlayer(Player).Location.Z < CurrentPoint.GetPositionForPlayer(Player).Location.Z)
			return false;

		return true;
	}

	void RevealedActivate()
	{
		for(AHazePlayerCharacter Player : Game::Players)
		{
			if(!IsValid())
				continue;
			if(!CanPlayerUse(Player))
				continue;

			UPlayerRespawnComponent OtherRespawnComp = UPlayerRespawnComponent::GetOrCreate(Player.OtherPlayer);
			ARespawnPoint OtherPoint = OtherRespawnComp.StickyRespawnPoint;
			if(OtherPoint != nullptr && ActorLocation.Z > OtherPoint.ActorLocation.Z + 25)
				continue;

			Player.SetStickyRespawnPoint(this);
		}
	}
}