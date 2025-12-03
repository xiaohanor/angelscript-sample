class UIslandWalkerSpinningLaserBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);
	default Requirements.Add(EBasicBehaviourRequirement::Perception);

	UIslandWalkerSettings Settings;
	UIslandWalkerComponent WalkerComp;
	UIslandWalkerAnimationComponent WalkerAnimComp;
	UIslandWalkerSwivelComponent Swivel;
	UIslandWalkerShellCasingsLauncher CasingsLauncher;

	bool bActiveLaser = false;
	float SpinSign = 1.0;
	FHazeAcceleratedFloat AccYawSpeed;
	FHazeAcceleratedFloat AccLaserHeight;
	FHazeAcceleratedFloat AccTrackingDuration;
	AHazePlayerCharacter Target;
	FBasicAIAnimationActionDurations Durations;

	float EjectShellTime;
	float EjectShellInterval;
	FVector CasingsLauncherPrevLocation;

	FVector PrevShotStart;
	FVector PrevShotEnd;

	TPerPlayer<float> LastDamageTime;

	float SquashTimeStart = BIG_NUMBER;
	float SquashTimeEnd = BIG_NUMBER;
	TArray<UIslandWalkerStompComponent> Stomps;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UIslandWalkerSettings::GetSettings(Owner);
		WalkerComp = UIslandWalkerComponent::Get(Owner);
		Swivel = UIslandWalkerSwivelComponent::Get(Owner);
		WalkerAnimComp = UIslandWalkerAnimationComponent::Get(Owner);
		CasingsLauncher = UIslandWalkerShellCasingsLauncher::Get(Owner);
		Owner.GetComponentsByClass(Stomps);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(!TargetComp.HasValidTarget())
			return false;
		if (!WalkerComp.CanPerformAttack(EISlandWalkerAttackType::SpinningLaser))
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

		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		WalkerComp.LastAttack = EISlandWalkerAttackType::SpinningLaser;
		WalkerComp.LaserAttackCount++;
		bActiveLaser = false;

		for (AHazePlayerCharacter Player : Game::Players)
		{
			LastDamageTime[Player] = -BIG_NUMBER;
		}

		AccYawSpeed.SnapTo(Swivel.SwivelVelocity);
		AccTrackingDuration.SnapTo(Settings.SpinningLaserTrackingDuration + 5.0);

		// Spin to the right or left?
		SpinSign = 1.0;
		if (Swivel.WorldRotation.RightVector.DotProduct(TargetComp.Target.ActorLocation - Owner.ActorLocation) < 0.0)
			SpinSign = -1.0;

		float StartHeight = (WalkerComp.ArenaLimits.Height - WalkerComp.Laser.WorldLocation.Z) / Settings.SpinningLaserMinRange;
		AccLaserHeight.SnapTo(StartHeight);

		PrevShotStart = WalkerComp.Laser.WorldLocation;
		PrevShotEnd = WalkerComp.Laser.WorldLocation + WalkerComp.Laser.ForwardVector * 1000.0;

		Durations.Telegraph = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::SpinningLaser, SubTagWalkerSpinningLaser::Start, Settings.SpinningLaserTelegraphDuration);
		Durations.Anticipation = Settings.SpinningLaserSpinUpDuration; // Laser will be active here
		Durations.Action = Settings.SpinningLaserSpinDuration + Settings.SpinningLaserSpinDownDuration;
		Durations.Recovery = WalkerAnimComp.GetFinalizedTotalDuration(FeatureTagWalker::SpinningLaser, SubTagWalkerSpinningLaser::End, Settings.SpinningLaserRecoveryDuration);
		AnimComp.RequestFeature(FeatureTagWalker::SpinningLaser, SubTagWalkerSpinningLaser::Start, EBasicBehaviourPriority::Medium, this, Durations.Telegraph);
		WalkerAnimComp.HeadAnim.RequestFeature(FeatureTagWalker::SpinningLaser, SubTagWalkerSpinningLaser::Start, EBasicBehaviourPriority::Medium, this, Durations.Telegraph);

		CasingsLauncher.ReserveShellCasings(Math::TruncToInt(Durations.Action * Settings.GatlingCasingsPerSecond) + 1);
		EjectShellTime = Durations.Telegraph;
		EjectShellInterval = 1.0 / float(Settings.GatlingCasingsPerSecond);
		CasingsLauncherPrevLocation = CasingsLauncher.WorldLocation;

		SquashTimeStart = Durations.Telegraph * 0.5;
		SquashTimeEnd = Durations.Telegraph * 0.8;

		UIslandWalkerEffectHandler::Trigger_OnTelegraphLaser(Owner, FIslandWalkerLaserEventData(WalkerComp.Laser, Settings.LaserBeamWidth));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		if (ActiveDuration > FullSpinTime)
			Cooldown.Set(Settings.SpinningLaserCooldown);
		
		AnimComp.ClearFeature(this);	
		WalkerAnimComp.HeadAnim.ClearFeature(this);	

		if (bActiveLaser)
			UIslandWalkerEffectHandler::Trigger_OnStoppedLaser(Owner);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bActiveLaser && Durations.IsInAnticipationRange(ActiveDuration))
			PowerUpLaser();

		if (bActiveLaser)
		{
			UpdateLaser(DeltaTime);
			if (Durations.IsInRecoveryRange(ActiveDuration))
				PowerDownLaser();
		} 

		UpdateSpin(DeltaTime);

		if (bActiveLaser && (ActiveDuration > EjectShellTime) && (DeltaTime > 0.0))
		{
			CasingsLauncher.Launch((CasingsLauncher.WorldLocation - CasingsLauncherPrevLocation) / DeltaTime);
			EjectShellTime += EjectShellInterval;
		}
		CasingsLauncherPrevLocation = CasingsLauncher.WorldLocation;

		if ((ActiveDuration > SquashTimeStart) && (ActiveDuration < SquashTimeEnd))
		{
			// Check if squashed under descending body
			FVector SquishFront = Owner.ActorLocation + Owner.ActorForwardVector * 450.0;
			FVector SquishBack = Owner.ActorLocation - Owner.ActorForwardVector * 400.0;
			float SquishRadius = 340.0;
			for (AHazePlayerCharacter Squishy : Game::Players)
			{
				if (!Squishy.HasControl())
					continue;
				if (Squishy.ActorLocation.Z > Owner.ActorLocation.Z + 800.0)
					continue;
				if (!Squishy.ActorLocation.IsInsideTeardrop2D(SquishFront, SquishBack, SquishRadius, SquishRadius))		
					continue;
				if (Squishy.IsAnyCapabilityActive(PlayerMovementTags::Slide))
					continue;
				Squishy.DealTypedDamage(Owner, 1.0, EDamageEffectType::ObjectLarge, EDeathEffectType::ObjectLarge);
			}
		}

		if ((ActiveDuration < Durations.Telegraph * 0.5) || (Durations.GetRecoveryRangeAlpha(ActiveDuration) > 0.5))
		{
			// Check if squashed by legs when moving down or up
			for (UIslandWalkerStompComponent Stomp : Stomps)
			{
				Stomp.UpdateStomp(DeltaTime);
				Stomp.StompPlayers();
			}
		}
	}

	void UpdateSpin(float DeltaTime)
	{
		if (ActiveDuration < Durations.Telegraph)
			AccYawSpeed.AccelerateTo(0.0, Settings.SpinningLaserTelegraphDuration * 2.0, DeltaTime);
		else if (ActiveDuration < FullSpinTime)
			AccYawSpeed.AccelerateTo(Settings.SpinningLaserDegreesPerSecond * SpinSign, Settings.SpinningLaserSpinUpDuration, DeltaTime);
		else if (ActiveDuration > SpinDownTime)
			AccYawSpeed.AccelerateTo(0.0, Settings.SpinningLaserSpinDownDuration, DeltaTime);
		Swivel.Swivel(AccYawSpeed.Value);
	}

	float GetFullSpinTime() const property
	{
		return Durations.Telegraph + Settings.SpinningLaserSpinUpDuration;
	}

	float GetSpinDownTime() const property
	{
		return Durations.Telegraph + Settings.SpinningLaserSpinUpDuration + Settings.SpinningLaserSpinDuration;
	}

	void PowerUpLaser()
	{
		// No need for networking, this starts at deterministic time
		bActiveLaser = true;
		WalkerComp.Laser.EndLocation = WalkerComp.Laser.WorldLocation + WalkerComp.Laser.WorldRotation.ForwardVector * Settings.SpinningLaserMinRange;
		WalkerComp.Laser.EndLocation.Z = WalkerComp.ArenaLimits.Height;
		UIslandWalkerEffectHandler::Trigger_OnStartedLaser(Owner, FIslandWalkerLaserEventData(WalkerComp.Laser, Settings.LaserBeamWidth, true));
	}

	void PowerDownLaser()
	{
		// No need for networking, this starts at deterministic time
		bActiveLaser = false;
		AnimComp.RequestSubFeature(SubTagWalkerSpinningLaser::End, this);
		UIslandWalkerEffectHandler::Trigger_OnStoppedLaser(Owner);
	}

	void UpdateLaser(float DeltaTime)
	{
		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		FVector PivotLoc = Swivel.WorldLocation;

		AccTrackingDuration.AccelerateTo(Settings.SpinningLaserTrackingDuration, Settings.SpinningLaserSpinUpDuration, DeltaTime);

		FVector EmitterLoc = WalkerComp.Laser.WorldLocation;

		// Track target height
		FVector TargetLoc = Target.ActorLocation + FVector(0.0, 0.0, 40.0);
		float RelevantDistance = TargetLoc.Dist2D(PivotLoc) - EmitterLoc.Dist2D(PivotLoc);
		if (RelevantDistance < Settings.SpinningLaserMinRange)
		{
			TargetLoc.Z = WalkerComp.ArenaLimits.Height;
			RelevantDistance = Settings.SpinningLaserMinRange;
		}

		AccLaserHeight.AccelerateTo((TargetLoc.Z - EmitterLoc.Z) / RelevantDistance, AccTrackingDuration.Value, DeltaTime);
		FVector AimDir = (WalkerComp.Laser.WorldRotation.ForwardVector.GetSafeNormal2D() + FVector(0.0, 0.0, AccLaserHeight.Value)).GetSafeNormal();
		WalkerComp.Laser.EndLocation = EmitterLoc + AimDir * Settings.LaserRange;

		// Deal damage
		FHitResult Obstruction = Trace.QueryTraceSingle(EmitterLoc, WalkerComp.Laser.EndLocation);
		if(Obstruction.bBlockingHit)
			WalkerComp.Laser.EndLocation = Obstruction.ImpactPoint + AimDir * 60.0;

		// Check if we swept over player
		float ImpactRangeSqr = EmitterLoc.DistSquared(WalkerComp.Laser.EndLocation);
		for (AHazePlayerCharacter TestPlayer : Game::Players)
		{
			if (ShouldHitPlayer(TestPlayer, EmitterLoc, WalkerComp.Laser.EndLocation, Obstruction, PrevShotStart, PrevShotEnd, DeltaTime))
			{
				// Damage and stumble is crumb synced, effects is fine if desynced
				if (Time::GetGameTimeSince(LastDamageTime[TestPlayer]) > 1.0)
				{
					TestPlayer.DealTypedDamage(Owner, Settings.LaserPlayerDamagePerSweep, EDamageEffectType::ProjectilesLarge, EDeathEffectType::ProjectilesLarge);
					LastDamageTime[TestPlayer] = Time::GameTimeSeconds;
				}
				TestPlayer.ApplyAdditiveHitReaction(WalkerComp.Laser.EndLocation - EmitterLoc, EPlayerAdditiveHitReactionType::Small);

				FVector StumbleMove = (TestPlayer.ActorLocation - EmitterLoc).GetNormalized2DWithFallback(-TestPlayer.ActorForwardVector) * 400.0;
				TestPlayer.ApplyStumble(StumbleMove, 0.6);
				
				UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(TestPlayer);
			}
		}

		float FFFrequency = 150.0;
		float FFIntensity = 0.3;
		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Sin(ActiveDuration * FFFrequency) * FFIntensity;
		FF.RightMotor = Math::Sin(-ActiveDuration * FFFrequency) * FFIntensity;
		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, WalkerComp.Laser.EndLocation, 1000, 1000);

		PrevShotStart = EmitterLoc;
		PrevShotEnd = WalkerComp.Laser.EndLocation;
	}

	bool ShouldHitPlayer(AHazePlayerCharacter Player, FVector Start, FVector End, FHitResult Obstruction, FVector PrevStart, FVector PrevEnd, float DeltaTime)
	{
		if (Obstruction.bBlockingHit && (Player == Obstruction.Actor))
			return true; // Direct hit!

		FVector PlayerLoc = Player.CapsuleComponent.WorldLocation;
		if (Start.DistSquared(End) < Start.DistSquared(PlayerLoc))
			return false; // We've hit something in front of player		

		if (PrevStart.DistSquared(PrevEnd) < PrevStart.DistSquared(PlayerLoc))
			return false; // We hit something in front of player last update		

		if ((End - Start).DotProduct(PlayerLoc - Start) < 0.0)
			return false; // Shooting away from player

		if (End.IsWithinDist(PrevEnd, 10.0 * DeltaTime))
			return false; // Tracking slowly, ignore all but direct hits

		// Check if player is intersecting sweep plane segment. 
		FVector SweepNormal = ((End - Start).CrossProduct(PrevEnd - PrevStart)).GetSafeNormal();
		FVector PlayerUp = Player.CapsuleComponent.UpVector;
		float PlayerRadius = Player.CapsuleComponent.ScaledCapsuleRadius;
		float CylinderHeight = Player.CapsuleComponent.ScaledCapsuleHalfHeight - PlayerRadius;
		FVector PlayerTop = PlayerLoc + PlayerUp * CylinderHeight;
		FVector PlayerBottom = PlayerLoc - PlayerUp * CylinderHeight;
		FVector Intersect = Math::LinePlaneIntersection(PlayerTop, PlayerBottom, End, SweepNormal);
		if (!Intersect.IsWithinDist(PlayerTop, PlayerRadius) && 
			!Intersect.IsWithinDist(PlayerBottom, PlayerRadius) && 
			((PlayerTop - Intersect).DotProduct(PlayerBottom - Intersect) > 0.0))
		{
			// Player capsule does not intersect sweep plane
			return false;			
		}	

		FVector FireLineInwards = (End - Start).CrossProduct(PlayerUp).GetSafeNormal();
		if (FireLineInwards.DotProduct(PrevEnd - End) < 0.0)
			FireLineInwards = -FireLineInwards;
		if (FireLineInwards.DotProduct((Intersect + FireLineInwards * PlayerRadius) - End) < 0.0)
			return false; // Capsule is in front of current line of fire
		
		FVector PrevLineInwards = (PrevEnd - PrevStart).CrossProduct(PlayerUp).GetSafeNormal();
		if (PrevLineInwards.DotProduct(End - PrevEnd) < 0.0)
			PrevLineInwards = -PrevLineInwards;
		if (PrevLineInwards.DotProduct((Intersect + PrevLineInwards * PlayerRadius) - PrevEnd) < 0.0)
			return false; // Capsule is behind previous line of fire

		// We could be behind an obstacle in between the two shots, but that's unlikely. Count as hit!
		return true;
	}
}