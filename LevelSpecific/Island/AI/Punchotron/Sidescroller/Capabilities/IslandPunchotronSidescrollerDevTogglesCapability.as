class UIslandPunchotronSidescrollerDevTogglesCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IslandPunchotronSidescrollerDevToggles::SidescrollerPunchotronsCategory.MakeVisible();
		IslandPunchotronSidescrollerDevToggles::DisableHaywireAttack.MakeVisible();		
		IslandPunchotronSidescrollerDevToggles::DisableCobraStrikeAttack.MakeVisible();
		IslandPunchotronSidescrollerDevToggles::DisableKickAttack.MakeVisible();
		IslandPunchotronSidescrollerDevToggles::DisableJumping.MakeVisible();
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

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ToggleDisableHaywireAttack();
		
		ToggleDisableCobraStrikeAttack();

		ToggleDisableKickAttack();

		ToggleDisableJumping();
	}

	void ToggleDisableHaywireAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronSidescrollerTags::IslandPunchotronSidescrollerTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotronSidescroller Punchotron = Cast<AAIIslandPunchotronSidescroller>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronSidescrollerDevToggles::DisableHaywireAttack.IsEnabled())
						Punchotron.bIsHaywireDisabled = true;
					else
						Punchotron.bIsHaywireDisabled = false;
				}
			}
		}
	}

	void ToggleDisableCobraStrikeAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronSidescrollerTags::IslandPunchotronSidescrollerTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotronSidescroller Punchotron = Cast<AAIIslandPunchotronSidescroller>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronSidescrollerDevToggles::DisableCobraStrikeAttack.IsEnabled())
						Punchotron.bIsCobraStrikeDisabled = true;
					else
						Punchotron.bIsCobraStrikeDisabled = false;
				}
			}
		}
	}
	
	void ToggleDisableKickAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronSidescrollerTags::IslandPunchotronSidescrollerTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotronSidescroller Punchotron = Cast<AAIIslandPunchotronSidescroller>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronSidescrollerDevToggles::DisableKickAttack.IsEnabled())
						Punchotron.bIsKickDisabled = true;
					else
						Punchotron.bIsKickDisabled = false;
				}
			}
		}
	}

void ToggleDisableJumping()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronSidescrollerTags::IslandPunchotronSidescrollerTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotronSidescroller Punchotron = Cast<AAIIslandPunchotronSidescroller>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronSidescrollerDevToggles::DisableJumping.IsEnabled())
						Punchotron.bIsJumpDisabled = true;
					else
						Punchotron.bIsJumpDisabled = false;
				}
			}
		}
	}

#endif
};