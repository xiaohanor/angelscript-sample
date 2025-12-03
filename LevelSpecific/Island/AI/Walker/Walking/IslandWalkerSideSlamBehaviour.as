struct FIslandWalkerSideSlamParams
{
	bool bLeft = false;
}

class UIslandWalkerSideSlamBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings Settings;

	AHazePlayerCharacter TargetPlayer;
	UTargetTrailComponent TargetTrail;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerSwivelComponent Swivel;

	TArray<AHazePlayerCharacter> AvailableTargets;
	FVector Destination;
	bool bLeftSlam;

	FBasicAIAnimationActionDurations Durations;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		UTargetTrailComponent::GetOrCreate(Game::Mio);
		UTargetTrailComponent::GetOrCreate(Game::Zoe);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandWalkerSideSlamParams& OutParams) const
	{
		if(!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!WalkerComp.CanPerformAttack(EISlandWalkerAttackType::SideSlam))
		 	return false;
		if (WalkerComp.TrackTargetDuration < Settings.SideSlamFrustrationTime)
			return false;
	
		OutParams.bLeft = (Owner.ActorRightVector.DotProduct(TargetComp.Target.ActorLocation - Owner.ActorLocation) < 0.0);
 		return true;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Durations.GetTotal())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandWalkerSideSlamParams Params)
	{
		Super::OnActivated();

		WalkerComp.LastAttack = EISlandWalkerAttackType::SideSlam;
		bLeftSlam = Params.bLeft;	
	
		TargetPlayer = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetTrail = UTargetTrailComponent::Get(TargetPlayer);

		Durations.Telegraph = Settings.SideSlamTelegraphDuration;
		Durations.Anticipation = Settings.SideSlamAnticipationDuration;
		Durations.Action = Settings.SideSlamActionDuration;
		Durations.Recovery = Settings.SideSlamRecoverDuration;
		//FName Tag = (bLeftSlam ? FeatureTagWalker::LeftSlam : FeatureTagWalker::RightSlam); 
		//AnimComp.RequestAction(Tag, EBasicBehaviourPriority::Medium, this, Durations);

		Destination = TargetPlayer.ActorLocation + TargetTrail.GetAverageVelocity(0.5) * Settings.SideSlamTargetPredictionTime;
		AvailableTargets = Game::Players;

		UBasicAIMovementSettings::SetTurnDuration(Owner, Settings.SideSlamTurnDuration, this, EHazeSettingsPriority::Gameplay);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > Settings.SideSlamTelegraphDuration)
			Cooldown.Set(Settings.SideSlamCooldown);
		Owner.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(Durations.IsInTelegraphRange(ActiveDuration))
			Destination = TargetPlayer.ActorLocation + TargetTrail.GetAverageVelocity(0.5) * Settings.SideSlamTargetPredictionTime;

		// if (Durations.IsBeforeAction(ActiveDuration))	
		// 	DestinationComp.RotateInDirection((Destination - Owner.ActorLocation).RotateAngleAxis());

		if (Durations.IsInActionRange(ActiveDuration))
			DealSlamDamage();
	}

	void DealSlamDamage()
	{
		FVector Offset = Settings.SideSlamDamageAreaOffset;
		if (bLeftSlam)
			Offset.Y *= -1.0;
		FVector Epicenter = Owner.ActorTransform.TransformPosition(Offset);
		for(int i = AvailableTargets.Num() - 1; i >= 0; i--)
		{
			AHazePlayerCharacter Player = AvailableTargets[i];
			if (!IsInDamageZone(Player.ActorLocation, Epicenter))
				continue;

			Player.DealTypedDamage(Owner, Settings.SideSlamDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);

			FKnockdown Knockdown;
			FVector Dir = (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector);
			float Force = Math::Max(2000 - Owner.ActorLocation.Distance(Player.ActorLocation), 0);
			Knockdown.Move = Dir * Force;
			Knockdown.Duration = 1.0;
			Player.ApplyKnockdown(Knockdown);
			UPlayerDamageEventHandler::Trigger_TakeBigDamage(Player);

			AvailableTargets.RemoveAt(i);
		}

		// Kill any minions foolish enough to be in the way
		UHazeTeam BuzzerTeam = HazeTeam::GetTeam(IslandBuzzerTags::IslandBuzzerTeam);
		TArray<UBasicAIHealthComponent> FormerMinions;
		if(BuzzerTeam != nullptr && BuzzerTeam.GetMembers().Num() > 0)
		{
			for(AHazeActor Buzzer: BuzzerTeam.GetMembers())
			{
				if (Buzzer == nullptr)
					continue;
				if (!IsInDamageZone(Buzzer.ActorLocation, Epicenter))
					continue;
				UBasicAIHealthComponent HealthComp = UBasicAIHealthComponent::Get(Buzzer);
				if((HealthComp != nullptr) && HealthComp.IsAlive())
					FormerMinions.Add(HealthComp);
			}
		}
		for (UBasicAIHealthComponent VictimHealth : FormerMinions)
		{
			VictimHealth.TakeDamage(BIG_NUMBER, EDamageType::Default, Owner);
		}

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugCylinder(Epicenter, Epicenter + FVector(0,0,Settings.SideSlamDamageAreaHeight), Settings.SideSlamDamageAreaRadius, 24, FLinearColor::Red, 10.0);		
#endif		
	}

	bool IsInDamageZone(FVector Loc, FVector Epicenter)
	{
		if (Loc.Z > Epicenter.Z + Settings.SideSlamDamageAreaHeight) 
			return false;
		if (!Loc.IsWithinDist2D(Epicenter, Settings.SideSlamDamageAreaRadius))
			return false;
		return true;
	}
}