class UIslandPunchotronSidescrollerCobraStrikeAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	default CapabilityTags.Add(BasicAITags::Attack);

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	UIslandPunchotronAttackComponent AttackComp;
	UIslandPunchotronCooldownComponent CooldownComp;
	UIslandPunchotronPanelTriggerComponent PanelComp;
	UIslandPunchotronSettings Settings;
	UPathfollowingSettings PathingSettings;
	TPerPlayer<bool> HasHitPlayer;
	
	AAIIslandPunchotronSidescroller Punchotron;

	FBasicAIAnimationActionDurations Durations;

	float MinLocationX;
	float MaxLocationX;
	float PlatformEdgeMinLocationX;
	float PlatformEdgeMaxLocationX;
	bool bHasStartedBreaking = false;
	bool bIsIgnoringPlatformCollision = false;
	bool bHasPlatformEdge = false;


	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		AttackComp = UIslandPunchotronAttackComponent::GetOrCreate(Owner);
		CooldownComp = UIslandPunchotronCooldownComponent::GetOrCreate(Owner);
		PanelComp = UIslandPunchotronPanelTriggerComponent::GetOrCreate(Owner);
		Settings = UIslandPunchotronSettings::GetSettings(Owner);
		PathingSettings = UPathfollowingSettings::GetSettings(Owner);

		Punchotron = Cast<AAIIslandPunchotronSidescroller>(Owner);

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
	}
	

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{		
		if (!Super::ShouldActivate())
			return false;
#if EDITOR
		if (Cast<AAIIslandPunchotronSidescroller>(Owner).bIsCobraStrikeDisabled)
			return false;
#endif
		if (AttackComp.bIsAttacking)
			return false;
		if (PanelComp.bIsOnPanel)
			return false;
		if (!CooldownComp.IsCooldownOver(Owner.Class))
			return false;
		if (!Cooldown.IsOver())
			return false; 
		if (!TargetComp.HasValidTarget())
			return false;
		if (!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, Settings.CobraStrikeAttackMinRange))
		 	return false;
		if ( Math::Abs(Owner.ActorLocation.Z - TargetComp.Target.ActorLocation.Z) > 200)
			return false;
		if (!IslandPunchotron::IsOnGround(Owner.ActorLocation, 40.0, PathingSettings.bIgnorePathfinding))
			return false;
		if (!PathingSettings.bIgnorePathfinding)
		{
			FVector NavmeshLocation;
			if (!Pathfinding::FindNavmeshLocation(TargetComp.Target.ActorLocation, 10.0, 200.0, NavmeshLocation))
				return false;

			if (!Pathfinding::StraightPathExists(Owner.ActorLocation, NavmeshLocation))
				return false;
		}
		return true;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		AttackComp.bIsAttacking = true;
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);
		bHasEndedTelegraphing = false;
		bHasStartedTelegraphing = false;

		HasHitPlayer[Game::Mio] = false;
		HasHitPlayer[Game::Zoe] = false;
		CurrentTargetLocation = FVector::ZeroVector;


		Durations.Telegraph = Settings.CobraStrikeAttackTelegraphDuration;
		Durations.Anticipation = Settings.CobraStrikeAttackAnticipationDuration;
		Durations.Action = Settings.CobraStrikeAttackActionDuration;
		Durations.Recovery = Settings.CobraStrikeRecoveryDuration;		

		// Faster turns
		UIslandPunchotronSettings::SetTurnDuration(Owner, Settings.TurnDuration * 0.5, this);

		// Prevent running into wall
		UIslandSidescrollerGroundMovementSettings::SetUseConstrainVolume(Owner, true, this);

		UIslandPunchotronEffectHandler::Trigger_OnCobraAttackTelegraphStart(Owner);

		RequestAnimation();
		UpdateMovementBoundaries();
		UpdatePlatformEdges();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.CobraStrikeAttackDuration)
			return true;
		UPlayerGrappleComponent GrappleComp = UPlayerGrappleComponent::Get(TargetComp.Target);
		if (GrappleComp.Data.CurrentGrapplePoint != nullptr)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		AttackComp.bIsAttacking = false;
		float CooldownTime = Settings.CobraStrikeAttackCooldown + Settings.CooldownDuration;
		CooldownComp.SetCooldown(Owner.Class, CooldownTime); // cooldown between each attack variant
		GentCostComp.ReleaseToken(this, Settings.AttackTokenCooldown);
		AnimComp.ClearFeature(this);
		AttackComp.NextAttackState();
		UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStop(Owner);		
		UIslandPunchotronSettings::ClearTurnDuration(Owner, this);
		UIslandPunchotronSettings::ClearSidescrollerGroundFriction(Owner, this);
		
		// Permit running into wall again
		UIslandSidescrollerGroundMovementSettings::ClearUseConstrainVolume(Owner, this);
		
		bHasStartedBreaking = false;
		bIsIgnoringPlatformCollision = false;
		Punchotron.ClearMovementIgnoreOneWayPlatforms(this);
		if (Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.UnblockCapabilities(n"DamagePlayerOnTouch", this);		
	}

	bool bHasEndedTelegraphing = false;
	bool bHasStartedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Telegraphing phase / Anticipation phase				
		if (Durations.IsInAnticipationRange(ActiveDuration))
		{
			CobraStrikeTelegraph(DeltaTime);
		}
		if (Durations.IsInActionRange(ActiveDuration) && !bHasEndedTelegraphing) // End of Telegraphing phase
		{
			OnTelegraphEnded();
		}
		// Action phase - activate hitbox during time window
		else if (Durations.IsInActionRange(ActiveDuration))
		{
			CobraStrikeAttack(DeltaTime);
		}

		UpdateMovement(DeltaTime);

#if EDITOR
		DebugDraw();		
#endif
	}

	void CobraStrikeTelegraph(float DeltaTime)
	{
		if (!bHasStartedTelegraphing)
		{
			UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStart(Owner, FIslandPunchotronSpinningAttackTelegraphingParams(Punchotron.EyeTelegraphingLocation, TargetComp.Target));
			bHasStartedTelegraphing = true;
		}
		else if (ActiveDuration > Durations.Telegraph + Durations.Anticipation - 0.1)
		{
			UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);
		}
	}

	void OnTelegraphEnded()
	{	
		bHasEndedTelegraphing = true;
		UIslandPunchotronEffectHandler::Trigger_OnSpinningAttackTelegraphingStop(Owner);
		UIslandPunchotronEffectHandler::Trigger_OnJetsStart(Owner, FIslandPunchotronJetsParams(Punchotron.LeftJetLocation, Punchotron.RightJetLocation));
		
		if (!Owner.IsCapabilityTagBlocked(n"DamagePlayerOnTouch"))
			Owner.BlockCapabilities(n"DamagePlayerOnTouch", this);
	}

	void CobraStrikeAttack(float DeltaTime)
	{
		FVector ImpactLocation;
		// Hack for offsetting hit sphere when animation leans the mesh forward far away from actor location.
		float ExtraOffset = Math::GetMappedRangeValueClamped(FVector2D(2.2, 2.8), FVector2D(0, 80), ActiveDuration);
		ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * (Settings.CobraStrikeAttackHitOffset + ExtraOffset);
		for (AHazePlayerCharacter Player : Game::Players)
		{	
			if (!Player.HasControl())
				continue;
			if (HasHitPlayer[Player])
				continue;
						
			if (ImpactLocation.IsWithinDist(Player.ActorLocation, Settings.CobraStrikeAttackHitRadius))
			{
				HasHitPlayer[Player] = true;
				Player.DealTypedDamage(Owner, Settings.CobraStrikeAttackDamage, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);

				float KnockdownDistance = Settings.KnockdownDistance;
				float KnockdownDuration = Settings.KnockdownDuration;;
				if (KnockdownDistance > 0.0)
				{
					FKnockdown Knockdown;
					Knockdown.Move = Owner.ActorForwardVector * KnockdownDistance;
					Knockdown.Duration = KnockdownDuration;
					Player.ApplyKnockdown(Knockdown);
				}
				AttackComp.bEnableTaunt = true;
			}
		}
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Sphere("HitSphere", ImpactLocation, Settings.CobraStrikeAttackHitRadius);
#endif
	}

	private void UpdateMovement(const float DeltaTime)
	{	
		// Telegraph phase - update target location
		if (Durations.IsInTelegraphRange(ActiveDuration))
		{
			if (TargetComp.HasValidTarget())
			{
				DestinationComp.RotateTowards(TargetComp.Target.ActorLocation);
#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Status("RotateTowards", FLinearColor::DPink);
#endif
			}
			UpdateTargetLocation(DeltaTime);
			DestinationComp.MoveTowards(CurrentDestinationLocation, Settings.SidescrollerCobraStrikeAttackMoveSpeed * 0.05);
		}
		// Action phase
		else if (Durations.IsInActionRange(ActiveDuration))
		{
			float MoveSpeed = Settings.SidescrollerCobraStrikeAttackMoveSpeed;
			FVector ToDestination = (CurrentDestinationLocation - Owner.ActorLocation).GetSafeNormal2D();

			// Check for overshoot, and make sure we have some velocity and that it isn't pointing backwards.
			if (Owner.ActorVelocity.Size2D() > 100 && ToDestination.DotProduct(Owner.ActorHorizontalVelocity) < 0 && Owner.ActorVelocity.DotProduct(Owner.ActorForwardVector) > 0)
			{
				CurrentDestinationLocation = Owner.ActorLocation + Owner.ActorForwardVector * 100;
				MoveSpeed = Settings.SidescrollerCobraStrikeAttackMoveSpeed * 0.01;
				if (!bHasStartedBreaking)
				{
					UIslandPunchotronSettings::SetSidescrollerGroundFriction(Owner, Settings.SidescrollerGroundFriction * 3.0, this);
					UIslandPunchotronEffectHandler::Trigger_OnCobraAttackBrakeStart(Owner);
					bHasStartedBreaking = true;
				}
#if !RELEASE
				FTemporalLog TemporalLog = TEMPORAL_LOG(this);
				TemporalLog.Event("CurrentDestinationLocation changed by overshoot!");
				TemporalLog.Value("Owner.ActorVelocity.Size2D", Owner.ActorVelocity.Size2D());				
#endif
			}

			DestinationComp.MoveTowardsIgnorePathfinding(CurrentDestinationLocation, MoveSpeed);
		}
		
		// Offset edge detection for not getting stuck on platform
		if (bHasPlatformEdge)
		{
			if (ActiveDuration > Durations.Telegraph + Durations.Anticipation + Durations.Action * 0.25)
			{
				const float EdgeOffset = 100;
				if (Owner.ActorLocation.X > PlatformEdgeMaxLocationX - EdgeOffset || Owner.ActorLocation.X < PlatformEdgeMinLocationX + EdgeOffset)
				{
					if (!bIsIgnoringPlatformCollision)
					{
						Punchotron.AddMovementIgnoreOneWayPlatforms(this);
						bIsIgnoringPlatformCollision = true;
					}
				}
			}
		}
	}

	FVector CurrentTargetLocation;
	FVector CurrentDestinationLocation;
	private void UpdateTargetLocation(const float DeltaTime)
	{
		if (!TargetComp.HasValidTarget())
			return;

		CurrentTargetLocation = TargetComp.Target.ActorLocation; // this may be on the ground or up in the air.
		
		// Set target to one of the sides of the arena.
		FVector ToTargetDirX = (TargetComp.Target.ActorLocation - Owner.ActorLocation);
		ToTargetDirX.Y = 0.0;
		ToTargetDirX.Z = 0.0;
		ToTargetDirX = ToTargetDirX.GetSafeNormal();		

		if (ToTargetDirX.X > 0.0)
			CurrentDestinationLocation = FVector(MaxLocationX, Owner.ActorLocation.Y, Owner.ActorLocation.Z);
		else
			CurrentDestinationLocation = FVector(MinLocationX, Owner.ActorLocation.Y, Owner.ActorLocation.Z);

#if !RELEASE
		FTemporalLog TemporalLog = TEMPORAL_LOG(this);
		TemporalLog.Arrow("ToTargetDir", Owner.ActorLocation, Owner.ActorLocation + ToTargetDirX * 300);
		TemporalLog.Arrow("TargetComp.Target.ActorLocation + ToTargetDir", TargetComp.Target.ActorLocation, TargetComp.Target.ActorLocation + ToTargetDirX * 300);
#endif
	}
	

	void RequestAnimation()
	{
		AnimComp.RequestFeature(FeatureTagIslandPunchotron::CobraStrike, EBasicBehaviourPriority::Medium, this);
	}

	void UpdateMovementBoundaries()
	{
		TListedActors<AIslandSidescrollerConstrainMovementVolume> ConstrainVolumes = TListedActors<AIslandSidescrollerConstrainMovementVolume>();
		AIslandSidescrollerConstrainMovementVolume CurrentConstrainVolume;
		float BestSqrDist = MAX_flt;
		for (AIslandSidescrollerConstrainMovementVolume Volume : ConstrainVolumes)
		{
			float SqrDist = Volume.ActorLocation.DistSquared(Owner.ActorLocation);
			if (SqrDist < BestSqrDist)
			{
				BestSqrDist = SqrDist;
				CurrentConstrainVolume = Volume;
			}
		}
		check(CurrentConstrainVolume != nullptr, "Could not find a constrain movement volume!");

		const float Offset = 100;
		MinLocationX = CurrentConstrainVolume.GetMinLocationX() + Offset;
		MaxLocationX = CurrentConstrainVolume.GetMaxLocationX() - Offset;
	}

	void UpdatePlatformEdges()
	{
		bHasPlatformEdge = false;
		FMovementHitResult Hit = Punchotron.MoveComp.GetGroundContact();
		AIslandSidescrollerOneWayPlatform Platform = Cast<AIslandSidescrollerOneWayPlatform>(Hit.GetInternalHitResult().Actor);
		if (Platform != nullptr)
		{
			bHasPlatformEdge = true;
			FVector Origin;
			FVector BoxExtent;
			Platform.GetActorBounds(true, Origin, BoxExtent,);
			PlatformEdgeMinLocationX = (Origin - BoxExtent).X;
			PlatformEdgeMaxLocationX = (Origin + BoxExtent).X;
		}
	}

#if EDITOR
	void DebugDraw()
	{
		//Owner.bHazeEditorOnlyDebugBool = true;

		// Draw attack ranges
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			PrintScaled(f"CobraStrikeAttack, ActiveDuration={ActiveDuration:.2} out of " + Settings.CobraStrikeAttackDuration, 0.0, Scale = 2.f);
			FVector ToPlayer = (TargetComp.Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
			Debug::DrawDebugLine(Owner.ActorLocation, Owner.ActorLocation + ToPlayer * Settings.CobraStrikeAttackMaxRange, FLinearColor::DPink, Duration = 3.0);
		}

		// Draw hit sphere
		FVector ImpactLocation;
		ImpactLocation = Owner.ActorLocation + Owner.ActorForwardVector * Settings.CobraStrikeAttackHitOffset;
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(ImpactLocation, Settings.CobraStrikeAttackHitRadius, LineColor = FLinearColor::Red, Duration = 0.0);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void OnLogState(FTemporalLog TemporalLog)
	{
		TemporalLog.Sphere("CurrentTargetLocation", CurrentTargetLocation, 100, FLinearColor::Red);
		TemporalLog.Sphere("CurrentDestinationLocation", CurrentDestinationLocation, 100, FLinearColor::White);

		TemporalLog.Arrow("Owner.ActorVelocity.", Owner.ActorCenterLocation, Owner.ActorLocation + Owner.ActorVelocity * 5);
	}
}

