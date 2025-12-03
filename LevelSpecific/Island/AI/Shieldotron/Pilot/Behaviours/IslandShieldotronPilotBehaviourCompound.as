

class UIslandShieldotronPilotBehaviourCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);
	default TickGroupOrder = 90;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AAIIslandShieldotron ShieldotronPilot = Cast<AAIIslandShieldotron>(Owner);		

		// See if attached to something
		USceneComponent ParentActorComponent = ShieldotronPilot.RootComponent.AttachParent;		
		
		if (ParentActorComponent == nullptr && ShieldotronPilot.RespawnComp.Spawner != nullptr)
			ParentActorComponent = ShieldotronPilot.RespawnComp.Spawner.RootComponent.AttachParent;

		if (ParentActorComponent != nullptr)
		{
			ShieldotronPilot.DetachRootComponentFromParent();
			ShieldotronPilot.MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);			
			ShieldotronPilot.MoveComp.FollowComponentMovement(ParentActorComponent, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal);			
		}

		ShieldotronPilot.RespawnComp.OnRespawn.AddUFunction(this, n"OnOwnerRespawn");
	}

	UFUNCTION()
	private void OnOwnerRespawn()
	{
		AAIIslandShieldotron ShieldotronPilot = Cast<AAIIslandShieldotron>(Owner);
		ShieldotronPilot.MoveComp.ClearFollowEnabledOverride(this);
		ShieldotronPilot.MoveComp.UnFollowComponentMovement(this);

		// See if attached to something
		USceneComponent ParentActorComponent = ShieldotronPilot.RootComponent.AttachParent;		
		
		if (ParentActorComponent == nullptr && ShieldotronPilot.RespawnComp.Spawner != nullptr)
			ParentActorComponent = ShieldotronPilot.RespawnComp.Spawner.RootComponent.AttachParent;

		if (ParentActorComponent != nullptr)
		{
			ShieldotronPilot.DetachRootComponentFromParent();
			ShieldotronPilot.MoveComp.ApplyFollowEnabledOverride(this, EMovementFollowEnabledStatus::FollowEnabled);			
			ShieldotronPilot.MoveComp.FollowComponentMovement(ParentActorComponent, this, EMovementFollowComponentType::ReferenceFrame, EInstigatePriority::Normal);			
		}
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		UPathfollowingSettings::SetIgnorePathfinding(Owner, true, this, EHazeSettingsPriority::Override);						
		Owner.BlockCapabilities(BasicAITags::CompoundBehaviour, this);

		AAIIslandShieldotron ShieldotronPilot = Cast<AAIIslandShieldotron>(Owner);
		ShieldotronPilot.Mesh.HideBoneByName(n"LeftUpLeg", EPhysBodyOp::PBO_None);
		ShieldotronPilot.Mesh.HideBoneByName(n"RightUpLeg", EPhysBodyOp::PBO_None);

		float PilotOrbProjectileExpirationTime = UIslandShieldotronSettings::GetSettings(Owner).PilotOrbProjectileExpirationTime;
		UIslandShieldotronSettings::SetOrbProjectileExpirationTime(Owner, PilotOrbProjectileExpirationTime, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AAIIslandShieldotron ShieldotronPilot = Cast<AAIIslandShieldotron>(Owner);
		ShieldotronPilot.MoveComp.ClearFollowEnabledOverride(this);
		ShieldotronPilot.MoveComp.UnFollowComponentMovement(this);
		Owner.UnblockCapabilities(BasicAITags::CompoundBehaviour, this);
		ShieldotronPilot.Mesh.UnHideBoneByName(n"LeftUpLeg");
		ShieldotronPilot.Mesh.UnHideBoneByName(n"RightUpLeg");
		UIslandShieldotronSettings::ClearOrbProjectileExpirationTime(Owner, this);
	}



	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return UHazeCompoundRunAll()
				.Add(UHazeCompoundSelector()
					//.Try(UIslandShieldotronDamageReactionBehaviour())
					.Try(UBasicCrowdRepulsionBehaviour())
				)
				.Add(UHazeCompoundSelector()
					.Try(UIslandShieldotronStunnedBehaviour())
					.Try(UIslandShieldotronEntranceAnimationBehaviour())
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSelector()
							.Try(UIslandShieldotronTraceMortarAttackBehaviour())
							.Try(UHazeCompoundRunAll()
								.Add(UHazeCompoundSelector()
									.Try(UIslandShieldotronMeleeAttackBehaviour())
									.Try(UBasicEvadeBehaviour())									
									.Try(UIslandShieldotronPilotOrbAttackBehaviour())
								)
								.Add(UBasicTrackTargetBehaviour())
								.Add(UHazeCompoundSelector()
									.Try(UIslandShieldotronShuffleScenepointBehaviour())									
								)								
								.Add(UIslandShieldotronFindTargetBehaviour())
							)
						)
					)					
				)
			;
	}
}