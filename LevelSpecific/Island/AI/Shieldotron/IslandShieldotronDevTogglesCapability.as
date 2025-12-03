class UIslandShieldotronDevTogglesCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IslandShieldotronDevToggles::ShieldotronsCategory.MakeVisible();
		IslandShieldotronDevToggles::DisableAggressiveTeam.MakeVisible();
		IslandShieldotronDevToggles::DisableOrbAttack.MakeVisible();
		IslandShieldotronDevToggles::DisableMortarAttack.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ToggleDisableAggressiveTeam();

		ToggleDisableOrbAttack();

		ToggleDisableMortarAttack();
	}

	private void ToggleDisableAggressiveTeam()
	{
		if (IslandShieldotronDevToggles::DisableAggressiveTeam.IsEnabled())
		{
			UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);		
			if (Team != nullptr)
			{
				for (AHazeActor Member : Team.GetMembers())
					Member.AddActorDisable(this);
			}			
		}
		else
		{
			UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);		
			if (Team != nullptr)
			{
				for (AHazeActor Member : Team.GetMembers())
					Member.RemoveActorDisable(this);
			}
		}
	}

	private TArray<AHazeActor> OrbAttackBlocks;
	private void ToggleDisableOrbAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronTeam);		
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandShieldotron Shieldotron = Cast<AAIIslandShieldotron>(Member);
				if (Shieldotron != nullptr)
				{
					if (IslandShieldotronDevToggles::DisableOrbAttack.IsEnabled() && !OrbAttackBlocks.Contains(Shieldotron))
					{
						Shieldotron.BlockCapabilities(n"OrbAttack", this);
						OrbAttackBlocks.AddUnique(Shieldotron);
					}
					else if (OrbAttackBlocks.Contains(Shieldotron))
					{
						Shieldotron.UnblockCapabilities(n"OrbAttack", this);
						OrbAttackBlocks.Remove(Shieldotron);
					}
				}
			}
		}		
	}

	private TArray<AHazeActor> MortarAttackBlocks;
	private void ToggleDisableMortarAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronTeam);		
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandShieldotron Shieldotron = Cast<AAIIslandShieldotron>(Member);
				if (Shieldotron != nullptr)
				{
					if (IslandShieldotronDevToggles::DisableMortarAttack.IsEnabled() && !MortarAttackBlocks.Contains(Shieldotron))
					{
						Shieldotron.BlockCapabilities(n"MortarAttack", this);
						MortarAttackBlocks.AddUnique(Shieldotron);
					}
					else if (MortarAttackBlocks.Contains(Shieldotron))
					{
						Shieldotron.UnblockCapabilities(n"MortarAttack", this);
						MortarAttackBlocks.Remove(Shieldotron);
					}
				}
			}
		}		
	}

};