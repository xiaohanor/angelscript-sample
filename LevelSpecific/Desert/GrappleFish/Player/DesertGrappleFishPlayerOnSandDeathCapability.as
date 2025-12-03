class UDesertGrappleFishPlayerOnSandDeathCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	
	default CapabilityTags.Add(BlockedWhileIn::Swing);
	default CapabilityTags.Add(n"OnSandDeath");

	default TickGroup = EHazeTickGroup::LastDemotable;
	default TickGroupOrder = 100;

	bool bOnSandPreviousFrame = false;
	bool bOnSandThisFrame = false;
	float TimeWhenHitSand = 0;

	UHazeMovementComponent MoveComp;
	UDesertGrappleFishPlayerComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MoveComp = UHazeMovementComponent::Get(Player);
		PlayerComp = UDesertGrappleFishPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Desert::GetRelevantLandscapeLevel() != ESandSharkLandscapeLevel::Secondary)
			return false;
		
		if (Player.IsPlayerDead() || Player.IsPlayerRespawning())
			return false;

		if (PlayerComp.State == EDesertGrappleFishPlayerState::Riding)
		{
			return false;
		}
		else
		{
			if (!IsLandscape(MoveComp.GroundContact.Actor))
				return false;

			if (!(MoveComp.PreviousHadGroundContact() && MoveComp.PreviousGroundContact.Actor == MoveComp.GroundContact.Actor))
				return false;

			return true;
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.KillPlayer();
	}

	bool IsLandscape(AActor Actor) const
	{
		if (Actor != nullptr)
		{
			auto Landscape = UDesertLandscapeComponent::Get(Actor);
			if (Landscape != nullptr)
				return true;
		}

		return false;
	}
}