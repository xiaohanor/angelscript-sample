class UIslandForceFieldStateComponent : UActorComponent
{
	// Whether the opposite colored force field should kill the grenade on contact.
	UPROPERTY(EditAnywhere)
	bool bShouldKillGrenade = true;

	bool bForceFieldIsOnEnemy = true;

	// The currently valid active shield
	EIslandForceFieldType CurrentForceFieldType = EIslandForceFieldType::MAX;
		
	void SetCurrentForceFieldType(EIslandForceFieldType Type)
	{
		CurrentForceFieldType = Type;

		if(!bShouldKillGrenade)
			return;

		for(auto Player : Game::Players)
		{
			auto GrenadeComp = UIslandRedBlueStickyGrenadeUserComponent::Get(Player);
			if(GrenadeComp == nullptr)
				continue;

			if(GrenadeComp.Grenade.AttachParentActor == Owner && !CanPlayerHitCurrentForceField(Player))
				GrenadeComp.Grenade.ExternalTriggerHitOppositeColorShield();
		}
	}

	void Reset()
	{
		CurrentForceFieldType = EIslandForceFieldType::MAX;
	}

	bool IsActive()
	{
		return CurrentForceFieldType != EIslandForceFieldType::MAX;
	}

	bool CanPlayerHitCurrentForceField(AHazePlayerCharacter Player)
	{		
		if (IslandForceField::GetPlayerForceFieldType(Player) == CurrentForceFieldType)
			return true;
		
		if (CurrentForceFieldType == EIslandForceFieldType::Both)
			return true;

		// This case lets player stick a grenade to an AI whose shield has been depleted.
		if (CurrentForceFieldType == EIslandForceFieldType::MAX)
			return true;

		return false;
	}
};