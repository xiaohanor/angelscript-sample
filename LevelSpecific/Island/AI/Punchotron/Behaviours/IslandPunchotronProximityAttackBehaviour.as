struct FIslandPunchotronProximityAttackParams
{
	AHazePlayerCharacter TargetPlayer;
	bool bIsLeftSwingAttack;
};


class UIslandPunchotronProximityAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	//default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	default CapabilityTags.Add(BasicAITags::Attack);

	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronPanelTriggerComponent PanelComp;
	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	TPerPlayer<bool> HasHitPlayer;

	AAIIslandPunchotron Punchotron;
	AHazePlayerCharacter TargetPlayer;

	bool bIsLeftSwingAttack = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		PanelComp = UIslandPunchotronPanelTriggerComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);

		Punchotron = Cast<AAIIslandPunchotron>(Owner);

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}
	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandPunchotronProximityAttackParams& Params) const
	{		
		if (!Super::ShouldActivate())
			return false;
		if (!AttackComp.bIsProximityAttackEnabled)
			return false;
		if (AttackComp.bIsAttacking)
			return false;
		if (!Cooldown.IsOver())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;

		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (PanelComp.bIsOnPanel)
		{
			// Is any player within range?
			AHazePlayerCharacter ClosestPlayer = Game::GetClosestPlayer(Owner.ActorCenterLocation);
			if (ClosestPlayer != Player && Owner.ActorVelocity.Size2D() < Settings.ProximityAttackPanelChangeTargetMaxSpeed && TargetComp.IsValidTarget(ClosestPlayer))
				Player = ClosestPlayer;
		}
		if (!Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.ProximityAttackMaxRange))
			return false;
		Params.TargetPlayer = Player;
		Params.bIsLeftSwingAttack = CoinFlip();

		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandPunchotronProximityAttackParams Params)
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		AttackComp.bIsInterruptAttack = true;
		bHasStartedAttackAnimation = false;
		bHasStartedTelegraphing = false;

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		TargetPlayer = Params.TargetPlayer;
		bIsLeftSwingAttack = Params.bIsLeftSwingAttack;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.ProximityAttackDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		AttackComp.bIsInterruptAttack = false;		
		Cooldown.Set(Settings.ProximityAttackCooldown);
		CooldownComp.SetCooldown(Owner.Class, Settings.ProximityAttackCooldown); // cooldown between each attack variant
		AnimComp.ClearFeature(this);
		UIslandPunchotronEffectHandler::Trigger_OnProximityAttackTelegraphingStop(Owner);
	}

	bool bHasStartedAttackAnimation = false;
	bool bHasStartedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetPlayer);
		if (!bHasStartedTelegraphing && ActiveDuration > 0.4)
		{
			UIslandPunchotronEffectHandler::Trigger_OnProximityAttackTelegraphingStart(Owner, FIslandPunchotronProximityAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetPlayer));		
			//RequestAnimation();
			bHasStartedTelegraphing = true;
		}
		
		if (ActiveDuration > Settings.ProximityAttackTelegraphDuration && !bHasStartedAttackAnimation)
		{
			RequestAnimation();
			bHasStartedAttackAnimation = true;			
			UIslandPunchotronEffectHandler::Trigger_OnSawbladeAttackSwing(Owner);
		}
		
				
		if (ActiveDuration > Settings.ProximityAttackTelegraphDuration + 0.4)
			UIslandPunchotronEffectHandler::Trigger_OnProximityAttackTelegraphingStop(Owner);

		// Activate hitbox during time window
		float StartActionTime = Settings.ProximityAttackTelegraphDuration + Settings.ProximityAttackAnticipationDuration;
		float EndActionTime = Settings.ProximityAttackTelegraphDuration + Settings.ProximityAttackAnticipationDuration + Settings.ProximityAttackActionDuration;
		if (ActiveDuration > StartActionTime &&	ActiveDuration < EndActionTime)
		{
			// First check actual hand location during swing.
			FVector HitSphereLocation;
			if (bIsLeftSwingAttack)
				HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"LeftHand").GetLocation();
			else
				HitSphereLocation = Cast<AHazeCharacter>(Owner).Mesh.GetSocketTransform(n"RightHand").GetLocation();
			
			FHazeTraceSettings Trace = Trace::InitObjectType(EObjectTypeQuery::PlayerCharacter);
			Trace.UseSphereShape(Settings.ProximityAttackHitRadius);
			FOverlapResultArray Overlaps = Trace.QueryOverlaps(HitSphereLocation);
			for (FOverlapResult Overlap : Overlaps.OverlapResults)
			{
				if (Overlap.Actor == nullptr)
					continue;
				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
				if (Player == nullptr)
					continue;
				if (!Player.HasControl())
					continue;
				if (IslandPunchotron::IsPlayerDashing(Player))
					continue;
				if (HasHitPlayer[Player])
					continue;

				HandleDamagePlayer(Player);
			}

			if (ActiveDuration > StartActionTime + 0.25)
			{
				// Close range overlap, auto hit player within radius
				for (AHazePlayerCharacter Player : Game::Players)
				{
					if (!Player.HasControl())
						continue;
					if (IslandPunchotron::IsPlayerDashing(Player))
						continue;
					if (HasHitPlayer[Player])
						continue;
					if (Owner.ActorCenterLocation.IsWithinDist(Player.ActorCenterLocation, Settings.ProximityAttackCloseRangeHitRadius))
					{
						HandleDamagePlayer(Player);
					}
				}
			}


#if EDITOR
			// Draw hit sphere
			//Owner.bHazeEditorOnlyDebugBool = true;
			if (Owner.bHazeEditorOnlyDebugBool)
			{
				Debug::DrawDebugSphere(HitSphereLocation, Settings.ProximityAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
				if (ActiveDuration > StartActionTime + 0.25)
					Debug::DrawDebugSphere(Owner.ActorCenterLocation, Settings.ProximityAttackCloseRangeHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
			}
#endif
		}

#if EDITOR
		// Draw attack ranges
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"ProximityAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.ProximityAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.ProximityAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
		}
#endif

	}

	void HandleDamagePlayer(AHazePlayerCharacter Player)
	{
		HasHitPlayer[Player] = true;		
		Player.DealTypedDamage(Owner, Settings.ProximityAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

		float KnockdownDistance = Settings.KnockdownDistance;
		float KnockdownDuration = Settings.KnockdownDuration;;
		if (KnockdownDistance > 0.0)
		{
			FKnockdown Knockdown;
			Knockdown.Move = Owner.ActorForwardVector * 0.001 + (Player.ActorLocation - Owner.ActorLocation).GetNormalized2DWithFallback(-Player.ActorForwardVector) * KnockdownDistance;
			Knockdown.Duration = KnockdownDuration;
			Player.ApplyKnockdown(Knockdown);
		}
		AttackComp.bEnableTaunt = true;
	}

	private int HandleDamageDealing(FOverlapResultArray& Overlaps)
	{
		int NumHitPlayers = 0;

		for (bool HitPlayer : HasHitPlayer)
		{
			if (HitPlayer)
				NumHitPlayers++;
		}

		for (FOverlapResult Overlap : Overlaps.OverlapResults)
		{
			if (NumHitPlayers >= 2)
				break;
			if (Overlap.Actor == nullptr)
				continue;
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Overlap.Actor);
			if (Player == nullptr)
				continue;
			if (!Player.HasControl())
				continue;
			if (IslandPunchotron::IsPlayerDashing(Player))
				continue;
			if (HasHitPlayer[Player])
				continue;				

			HasHitPlayer[Player] = true;
			NumHitPlayers++;
			
			Player.DealTypedDamage(Owner, Settings.ProximityAttackDamage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

			float KnockdownDistance = Settings.KnockdownDistance;
			float KnockdownDuration = Settings.KnockdownDuration;;
			if (KnockdownDistance > 0.0)
			{
				FKnockdown Knockdown;
				Knockdown.Move = Owner.ActorForwardVector * KnockdownDistance;
				Knockdown.Duration = KnockdownDuration;
				Player.ApplyKnockdown(Knockdown);
			}
		}				

		return NumHitPlayers;
	}


	void RequestAnimation()
	{
		if (bIsLeftSwingAttack)
		{
			AnimComp.RequestFeature(FeatureTagIslandPunchotron::CloseSwingLeft, EBasicBehaviourPriority::Medium, this);
		}
		else
		{
			AnimComp.RequestFeature(FeatureTagIslandPunchotron::CloseSwingRight, EBasicBehaviourPriority::Medium, this);
		}
	}

	bool CoinFlip() const
	{
		return Math::RandRange(1, 2) == 1;
	}
}

