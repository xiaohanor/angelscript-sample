class UIslandShieldotronAggressiveBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default TickGroupOrder = 90;
	
	bool bIsOrbAttackBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnUnspawn.AddUFunction(this, n"OnUnspawn");
	}

	UFUNCTION()
	private void OnUnspawn(AHazeActor RespawnableActor)
	{
		UHazeTeam AggressiveTeam = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);
		if (AggressiveTeam == nullptr)
			return;

		if (AggressiveTeam.IsMember(RespawnableActor) && AggressiveTeam.GetMembers().Num() == 1) // Last member
		{
			UHazeTeam EvasiveTeam = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
			if (EvasiveTeam == nullptr)
				return;

			TArray<AHazeActor> Members = EvasiveTeam.GetMembers();
			for (AHazeActor Member : Members)
			{
				Member.LeaveTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
				Member.JoinTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// Only aggressive team will activate
		UHazeTeam Team = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam);		
		if (Team == nullptr)
			return false;
		if (!Team.IsMember(Owner))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);
		UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(Owner);
		TargetComp.OnChangeTarget.AddUFunction(this, n"OnChangeTarget");
	}

	UFUNCTION()
	private void OnChangeTarget(AHazeActor NewTarget, AHazeActor OldTarget)
	{
		UIslandShieldotronAggressiveTeam AggressiveTeam = Cast<UIslandShieldotronAggressiveTeam>(HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronAggressiveTeam));
		if (AggressiveTeam != nullptr)
		{
			if (OldTarget != nullptr)
				AggressiveTeam.ReportStopChasing(OldTarget, Owner);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		ResetCompoundNodes();
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);

		UBasicAITargetingComponent TargetComp = UBasicAITargetingComponent::Get(Owner);
		TargetComp.OnChangeTarget.UnbindObject(this);

		if (!bIsOrbAttackBlocked)
			return;

		bIsOrbAttackBlocked = false;
		Owner.UnblockCapabilities(n"OrbAttack", this);
		UIslandShieldotronSettings::ClearAttackCooldown(Owner, this);
		UIslandShieldotronSettings::ClearAttackCooldownRandRangeMin(Owner, this);
		UIslandShieldotronSettings::ClearAttackCooldownRandRangeMax(Owner, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UHazeTeam EvasiveTeam = HazeTeam::GetTeam(IslandShieldotronTags::IslandShieldotronEvasiveTeam);
		if (EvasiveTeam != nullptr)
		{
			// Block orb attack while there is an evasive team
			if (bIsOrbAttackBlocked)
				return;

			bIsOrbAttackBlocked = true;
			Owner.BlockCapabilities(n"OrbAttack", this); // Only activate once evasive team turns aggressive.
		}
		else
		{
			if (bIsOrbAttackBlocked)
			{
				bIsOrbAttackBlocked = false;
				Owner.UnblockCapabilities(n"OrbAttack", this);
			}
			// When there is no evasive team
			UIslandShieldotronSettings Settings = UIslandShieldotronSettings::GetSettings(Owner);
			UIslandShieldotronSettings::SetAttackCooldown(Owner, 3.0, this);
			UIslandShieldotronSettings::SetAttackCooldownRandRangeMin(Owner, 0.0, this);
			UIslandShieldotronSettings::SetAttackCooldownRandRangeMax(Owner, 1.5, this);
		}	
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					//.Try(UIslandShieldotronDamageReactionBehaviour())
					.Try(UIslandShieldotronCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()
					.Try(UIslandShieldotronEntranceAnimationBehaviour())
					.Try(UIslandShieldotronLandBehaviour())
					.Try(UIslandShieldotronStunnedBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UHazeCompoundRunAll()
								.Add(UHazeCompoundSelector()
									.Try(UIslandShieldotronOrbAttackBehaviour())
									.Try(UIslandShieldotronCloseRangeAttackBehaviour())
									.Try(UIslandShieldotronMeleeAttackBehaviour())
								)
								.Add(UBasicTrackTargetBehaviour())
								.Add(UHazeCompoundSelector()
									.Try(UIslandShieldotronLeapTraversalChaseBehaviour())
									.Try(UIslandShieldotronAggressiveChaseBehaviour())
								)
								.Add(UIslandShieldotronFindTargetBehaviour())
							)
						)
					)					
				)
			;
	}
}