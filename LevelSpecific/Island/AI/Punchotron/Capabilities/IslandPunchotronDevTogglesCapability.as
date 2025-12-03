class UIslandPunchotronDevTogglesCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		IslandPunchotronDevToggles::PunchotronsCategory.MakeVisible();
		
		IslandPunchotronDevToggles::EnableForcefieldCutscene.MakeVisible();

		IslandPunchotronDevToggles::EnableAttackDecals.MakeVisible();
		//IslandPunchotronDevToggles::DisableHaywireAttack.MakeVisible();
		IslandPunchotronDevToggles::DisableProximityAttack.MakeVisible();
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
		ToggleOverrideEnableForcefieldCutscene();

		ToggleEnableAttackDecals();
		
		//ToggleDisableHaywireAttack();
		
		ToggleDisableCobraStrikeAttack();
		
		ToggleDisableProximityAttack();
	}

	private void ToggleOverrideEnableForcefieldCutscene()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotronBoss Punchotron = Cast<AAIIslandPunchotronBoss>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronDevToggles::EnableForcefieldCutscene.IsEnabled())
						UIslandPunchotronSettings::SetIsBossForcefieldCutsceneEnabled(Punchotron, true, this);
					else
						UIslandPunchotronSettings::ClearIsBossForcefieldCutsceneEnabled(Punchotron, this); // reset to default setting
				}
			}
		}
	}

	private void ToggleEnableAttackDecals()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronDevToggles::EnableAttackDecals.IsEnabled())
						Punchotron.AttackDecalComp.bIsDisabled = false;
					else
						Punchotron.AttackDecalComp.bIsDisabled = true;
				}
			}
		}
	}	

	void ToggleDisableHaywireAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronDevToggles::DisableHaywireAttack.IsEnabled())
						Punchotron.AttackComp.DevToggleDisabledIndices.AddUnique(Punchotron.AttackComp.StateIndexMap[EIslandPunchotronAttackState::HaywireAttack]);
					else
						Punchotron.AttackComp.DevToggleDisabledIndices.Remove(Punchotron.AttackComp.StateIndexMap[EIslandPunchotronAttackState::HaywireAttack]);
					
					Punchotron.AttackComp.UpdateAttackState();
				}
			}
		}
	}

	void ToggleDisableCobraStrikeAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronDevToggles::DisableCobraStrikeAttack.IsEnabled())
						Punchotron.AttackComp.DevToggleDisabledIndices.AddUnique(Punchotron.AttackComp.StateIndexMap[EIslandPunchotronAttackState::CobraStrikeAttack]);
					else
						Punchotron.AttackComp.DevToggleDisabledIndices.Remove(Punchotron.AttackComp.StateIndexMap[EIslandPunchotronAttackState::CobraStrikeAttack]);
					
					Punchotron.AttackComp.UpdateAttackState();
				}
			}
		}
	}

	private void ToggleDisableProximityAttack()
	{
		UHazeTeam Team = HazeTeam::GetTeam(IslandPunchotronTags::IslandPunchotronTeamTag);
		if (Team != nullptr)
		{
			for (AHazeActor Member : Team.GetMembers())
			{
				AAIIslandPunchotron Punchotron = Cast<AAIIslandPunchotron>(Member);
				if (Punchotron != nullptr)
				{
					if (IslandPunchotronDevToggles::DisableProximityAttack.IsEnabled())
						Punchotron.AttackComp.bIsProximityAttackEnabled = false;
					else
						Punchotron.AttackComp.bIsProximityAttackEnabled = true;
				}
			}
		}
	}	
#endif
};