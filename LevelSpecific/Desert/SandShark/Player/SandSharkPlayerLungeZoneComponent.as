class USandSharkPlayerLungeZoneComponent : UActorComponent
{
	AHazePlayerCharacter Player;
	TArray<ASandSharkExtendedLungeZone> OverlappedLungeZones;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}
	void AddExtendedLungeZone(ASandSharkExtendedLungeZone LungeZone)
	{
		OverlappedLungeZones.AddUnique(LungeZone);
	}

	void RemoveExtendedLungeZone(ASandSharkExtendedLungeZone LungeZone)
	{
		if (!OverlappedLungeZones.Contains(LungeZone))
			return;
		
		OverlappedLungeZones.RemoveSwap(LungeZone);
	}

	bool IsPlayerHeadedToZoneSafety()
	{
		for (auto Zone : OverlappedLungeZones)
		{
			FVector ToZone = (Zone.ActorLocation - Player.ActorLocation).GetSafeNormal2D();
			float Dot = Player.ActorForwardVector.DotProduct(ToZone);
			if (Dot >= 0.3)
				return true;
		}
		return false;
	}
};