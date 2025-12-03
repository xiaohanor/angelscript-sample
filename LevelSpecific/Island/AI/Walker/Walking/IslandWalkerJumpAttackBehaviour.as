
class UIslandWalkerJumpAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings WalkerSettings;
	UIslandWalkerLegsComponent LegsComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerSwivelComponent Swivel;
	UHazeSkeletalMeshComponentBase Mesh;
	
	TArray<AHazeActor> HitActors;
	bool bLanded = false;
	FBasicAIAnimationActionDurations Durations;

	AHazePlayerCharacter TargetPlayer;
	FVector TargetLocation;
	float JumpSpeed = 1800.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		WalkerSettings = UIslandWalkerSettings::GetSettings(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		LegsComp = UIslandWalkerLegsComponent::Get(Owner);
		Mesh = Cast<AHazeCharacter>(Owner).Mesh;
		TargetPlayer = Game::Mio;
		WalkerComp.SpawnShockWave();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(LegsComp.NumDestroyedLegs() < 2)
			return false;
		if(LegsComp.DestroyedLegTime == 0)
			return false;
		if(Time::GetGameTimeSince(LegsComp.DestroyedLegTime) < 0.2)
			return false;

		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Durations.GetTotal())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		WalkerComp.LastAttack = EISlandWalkerAttackType::Jump;
		LegsComp.DestroyedLegTime = 0;
		HitActors.Empty();
		Durations.Telegraph = WalkerSettings.JumpAttackTelegraph;
		Durations.Anticipation = WalkerSettings.JumpAttackAnticipation;
		Durations.Action = WalkerSettings.JumpAttackDuration;
		Durations.Recovery = WalkerSettings.JumpAttackRecovery;		
		WalkerAnimComp.FinalizeDurations(FeatureTagWalker::JumpAttack, NAME_None, Durations);
		AnimComp.RequestAction(FeatureTagWalker::JumpAttack, EBasicBehaviourPriority::Medium, this, Durations);
		WalkerAnimComp.HeadAnim.RequestAction(FeatureTagWalker::JumpAttack, EBasicBehaviourPriority::Medium, this, Durations);
		LegsComp.HideLegs();	
		bLanded = false;
		UpdateTargetLocation();
	}

	void UpdateTargetLocation()
	{
		TargetLocation = WalkerComp.ArenaLimits.GetAtArenaHeight(TargetPlayer.ActorLocation);
		if (Durations.Anticipation > 0.0)
			JumpSpeed = Owner.ActorLocation.Dist2D(TargetLocation) / Durations.Anticipation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	
		TargetPlayer = TargetPlayer.OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Swivel.Realign(Durations.Telegraph * 0.5, DeltaTime);	

		if (Durations.IsInTelegraphRange(ActiveDuration))
			UpdateTargetLocation();
		
		if (Durations.IsInAnticipationRange(ActiveDuration))
			DestinationComp.MoveTowards(TargetLocation, JumpSpeed);

		if(Durations.IsInActionRange(ActiveDuration))
		{
			if(!bLanded)
			{
				bLanded = true;
				FIslandWalkerJumpAttackLandedEventData Data = FIslandWalkerJumpAttackLandedEventData();
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"LeftFrontLeg5"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"LeftFrontMiddleLeg5"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"LeftBackMiddleLeg6"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"LeftBackLeg6"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"RightFrontLeg5"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"RightFrontMiddleLeg5"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"RightBackMiddleLeg6"));
				Data.LegLocations.Add(Mesh.GetSocketLocation(n"RightBackLeg6"));
				UIslandWalkerEffectHandler::Trigger_OnJumpAttackLanded(Owner, Data);
			}

			// Trigger shockwave. This will stop itself when appropriate.
			WalkerComp.ShockWave.StartShockwave(WalkerComp.ArenaLimits.GetAtArenaHeight(Owner.ActorLocation));

			auto BuzzerTeam = HazeTeam::GetTeam(IslandBuzzerTags::IslandBuzzerTeam);
			if(BuzzerTeam != nullptr && BuzzerTeam.GetMembers().Num() > 0)
			{
				for(AHazeActor Buzzer: BuzzerTeam.GetMembers())
				{
					if (Buzzer == nullptr)
						continue;
					if(HitActors.Contains(Buzzer)) 
						continue;
					if(!Buzzer.ActorLocation.IsWithinDist(Owner.ActorLocation, 1250))
						continue;
					HitActors.AddUnique(Buzzer);

					UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Buzzer);
					if(HealthComp != nullptr)
						HealthComp.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
				}
			}
		}
	}
}