class USkylineGeckoPounceAttackBehaviour : UBasicBehaviour
{	
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UWallclimbingComponent WallClimbingComp;
	USkylineGeckoSettings Settings;
	USkylineGeckoComponent GeckoComp;
	UHazeMovementComponent MoveComp;
	UBasicAIHealthComponent HealthComp;
	UHazeDecalComponent PounceDecal;
	UAnimInstanceAIBase	AnimInstance;

	FVector Destination;
	FVector PounceDirection;
	float PounceDistance;
	ASkylineTorReferenceManager Arena;
	AHazePlayerCharacter Target;
	USkylineGeckoConstrainedPlayerComponent TargetConstrainComp;
	FBasicAIAnimationActionDurations Durations;

	bool bIsJumping = false;
	bool bIsRecovering = false;
	float InViewDuration = 0;
	float PounceSpeed;
	float PrevDodgeTime;
	bool bShouldReleaseTokenEarly;
	// bool bIsConstraining = false;

	// We don't want to timescale pounce animation telegraph and recover parts that much, 
	// so just delay requesting animation for a while instead.
	float PounceAnimStartTime;
	FBasicAIAnimationActionDurations AnimDurations;

	const FName PounceAction = n"GeckoPounce";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Arena = TListedActors<ASkylineTorReferenceManager>().GetSingle();
		WallClimbingComp = UWallclimbingComponent::GetOrCreate(Owner);
		GeckoComp = USkylineGeckoComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		Settings = USkylineGeckoSettings::GetSettings(Owner);

		PounceDecal = UHazeDecalComponent::Get(Owner, n"PounceDecal");
		PounceDecal.DetachFromParent();

		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		AnimInstance = Cast<UAnimInstanceAIBase>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);

		GeckoComp.Initialize();
		for (AHazePlayerCharacter Player : Game::Players)
		{
			GeckoComp.Team.NumSequencePounce[Player] = 0;			
		}
	}

	UFUNCTION()
	private void OnTakeDamage(AHazeActor ActorTakingDamage, AHazeActor Attacker, float Damage, EDamageType DamageType)
	{
		// Reduce cooldown when hit by gravity blade for immediate retribution
		if (!IsActive() && Cooldown.IsSet() && (DamageType == EDamageType::MeleeSharp))
			Cooldown.Set(0.0);	// Note that we don't reset, we don't want to affect current tick.
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (ShouldCountInViewDuration())
			InViewDuration += DeltaTime;
		else	
			InViewDuration = 0.0;
		
		if (!Cooldown.IsOver())
		{
			if (GeckoComp.bOverturned)
				Cooldown.Set(1.0);
			else if (PrevDodgeTime < GeckoComp.LastDodgeStartTime)
				Cooldown.Set(0.0);
		}
	}

	bool ShouldCountInViewDuration() const
	{
		if (IsBlocked())
			return false;
		if (IsActive())
			return false;
		if (!WantsToPounce())
			return false;
		AHazePlayerCharacter PlayerTarget =  Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (!IsValid(PlayerTarget) || !SceneView::IsInView(PlayerTarget, Owner.ActorCenterLocation))
			return false;
		return true;
	}

	bool WantsToPounce() const
	{
		if (!TargetComp.HasValidTarget())
			return false;
		if (!TargetComp.GentlemanComponent.CanClaimToken(GeckoComp.PounceToken, this))
			return false;
		if (TargetConstrainComp != nullptr && TargetConstrainComp.IsConstrained())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToPounce())
			return false;
		if (GeckoComp.bIsLeaping.Get())
			return false;
		if (!Settings.PounceAttackAllowedWhenPlayerDown && IsTargetDown(TargetComp.Target))
			return false; 
		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.PounceAttackMinRange))
			return false;
		
		// After first pounce we want other geckos to follow with a sequence of pounces
		bool bFirstPounce = (Time::GetGameTimeSince(TargetComp.GentlemanComponent.GetLastActionTime(PounceAction)) > (Settings.PounceKeepTokenDuration + 0.2));
		float MaxRange = Settings.PounceAttackRange * (bFirstPounce ? 1.0 : 1.5);
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, MaxRange))
			return false;
		if (bFirstPounce && (InViewDuration < 0.5))
			return false;

		return true;
	}

	bool IsTargetDown(AHazeActor PounceTarget) const
	{
		if (PounceTarget.IsAnyCapabilityActive(n"Knockdown"))
			return true;
		if (PounceTarget.IsAnyCapabilityActive(n"Stumble"))
			return true;
		return false;		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;

		if (ActiveDuration > Durations.GetTotal())
			return true;

		if(Target.IsPlayerDead())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = Cast<AHazePlayerCharacter>(TargetComp.Target);
		TargetConstrainComp = USkylineGeckoConstrainedPlayerComponent::Get(Target);		
		TargetComp.GentlemanComponent.ClaimToken(GeckoComp.PounceToken, this);
		TargetComp.GentlemanComponent.ReportAction(PounceAction);
		GeckoComp.Team.NumSequencePounce[Target]++;
		bShouldReleaseTokenEarly = (GeckoComp.Team.NumSequencePounce[Target] < Settings.PounceSequenceMax);

		if (GetTargetLocation().IsWithinDist(Owner.ActorLocation, 10.0))
		{
			Cooldown.Set(1.0);
			return;		
		}
		Destination = GetTargetLocation();
		PounceDistance = Owner.ActorLocation.Dist2D(Destination);
		PounceDirection = (Destination - Owner.ActorLocation) * FVector(1.0, 1.0, 0.0) / PounceDistance;

		Durations.Telegraph = Settings.PounceTelegraphDuration;
		Durations.Anticipation = Math::Max(Settings.PounceJumpDuration, PounceDistance / Settings.PounceSpeed);
		Durations.Action = Settings.PounceAttackDuration;
		Durations.Recovery = Settings.PounceRecoverDuration;

		GeckoComp.StartTelegraph();

		// We want gecko to idle a while before starting attack instead of timescaling anim. 
		// Anim will use actual play rate except for anticipation (jump) period.
		AnimComp.RequestFeature(FeatureTagGecko::Locomotion, EBasicBehaviourPriority::Medium, this);
		AnimInstance.FinalizeDurations(FeatureTagGecko::PounceAttack, NAME_None, AnimDurations);
		AnimDurations.Anticipation = Durations.Anticipation;
		PounceAnimStartTime = (Durations.Telegraph - AnimDurations.Telegraph);
		if (PounceAnimStartTime < 0.0)
		{
			PounceAnimStartTime = 0.0;
			AnimDurations.Telegraph = Durations.Telegraph;
		}

		USkylineGeckoEffectHandler::Trigger_OnTelegraphPounce(Owner);
		bIsJumping = false;
		bIsRecovering = false;
		PrevDodgeTime = GeckoComp.LastDodgeStartTime;

		PounceSpeed = PounceDistance / Durations.Anticipation;

		WallClimbingComp.DestinationUpVector.Apply(Target.ActorUpVector, this, EInstigatePriority::Normal);
		GeckoComp.bAllowBladeHits.Apply(false, this);

		// bIsConstraining = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		
		if (GeckoComp.Team.NumSequencePounce[Target] < Settings.PounceSequenceMax)
		{
			UGentlemanComponent::Get(Target).ReleaseToken(GeckoComp.PounceToken, this);
		}
		else 
		{
			UGentlemanComponent::Get(Target).ReleaseToken(GeckoComp.PounceToken, this, Settings.PounceSequenceCooldown);
			GeckoComp.Team.NumSequencePounce[Target] = 0;
		}

		Cooldown.Set(Settings.PounceAttackCooldownDuration);
		if (!bIsRecovering)
			USkylineGeckoEffectHandler::Trigger_OnPounceEnd(Owner);
		Owner.ClearSettingsByInstigator(this);
		
		WallClimbingComp.DestinationUpVector.Clear(this);
		GeckoComp.bAllowBladeHits.Clear(this);

		if ((HealthComp.LastDamageType == EDamageType::MeleeSharp) && (Time::GetGameTimeSince(HealthComp.LastDamageTime) < Settings.PounceCooldown))
			Cooldown.Set(0.0); // Allow immediate pounce again since we got hit by blade during pounce
		else
			Cooldown.Set(Settings.PounceCooldown); // Wait a while before pouncing again

		GeckoComp.bShouldLeap.Clear(this);
		GeckoComp.bCanDodge.Clear(this);
		GeckoComp.FocusOffset = 0;

		GeckoComp.StopTelegraph();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Cooldown.IsSet())
			return; // Failed to get a target location on navmesh

		if (ActiveDuration > PounceAnimStartTime)
		{
			// Request pounce 
			PounceAnimStartTime = BIG_NUMBER;
			AnimComp.RequestAction(FeatureTagGecko::PounceAttack, EBasicBehaviourPriority::Medium, this, AnimDurations);
		}

		if (Durations.IsInTelegraphRange(ActiveDuration))
		{
			// If telegraphing while climbing on spline, we stay there!
			if(GeckoComp.CurrentClimbSpline != nullptr)
				DestinationComp.MoveAlongSpline(GeckoComp.CurrentClimbSpline, 0.0, GeckoComp.IsAlignedWithSpline(DestinationComp.FollowSplinePosition));
			GeckoComp.UpdateTelegraph(FLinearColor::Yellow, 15);
			
			// if(!bIsConstraining && TargetConstrainComp.IsConstrained())
			if(TargetConstrainComp.IsConstrained())
			{
				DeactivateBehaviour();
				return;
			}
		}

		if (HasControl() && !bIsJumping && Durations.IsInAnticipationRange(ActiveDuration))
			CrumbJump();

		if (bIsJumping)
		{
			// This will trigger correct movement capabilty. 
			GeckoComp.bShouldLeap.Apply(true, this);
			DestinationComp.MoveTowardsIgnorePathfinding(Destination, PounceSpeed);
			
			if (HasControl() && HasLanded()) 
				CrumbLand(CanHit(Target), CanConstrainTarget()); 
		}

		// Regular attack
		if (!bIsRecovering && Durations.IsInRecoveryRange(ActiveDuration))
			Recover();

		if (Durations.IsInTelegraphRange(ActiveDuration))
			DestinationComp.RotateTowards(Target.ActorLocation); // Telegraphing, rotate towards approximate destination (updating actual destination is expensive)
		else if (Durations.IsBeforeAction(ActiveDuration))
			DestinationComp.RotateInDirection(PounceDirection); // We now have a correct destination, which may differ from target location since it needs to be on navmesh

		if(TargetConstrainComp.IsConstrained() && HasLanded())
			DeactivateBehaviour();

		if (bShouldReleaseTokenEarly && (ActiveDuration > Settings.PounceKeepTokenDuration))
		{
			bShouldReleaseTokenEarly = false;	
			UGentlemanComponent::Get(Target).ReleaseToken(GeckoComp.PounceToken, this);
		}	

#if EDITOR
		if (Owner.bHazeEditorOnlyDebugBool)
			Debug::DrawDebugSphere(Owner.ActorLocation, 100, 12, FLinearColor::Red);		
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbJump()
	{
		GeckoComp.StopTelegraph();
		GeckoComp.SetEmissiveColor(FLinearColor::Yellow);
		bIsJumping = true;

		// Match gravity with target
		FVector TargetUp = Target.ActorUpVector;
		WallClimbingComp.DestinationUpVector.Apply(TargetUp, this, EInstigatePriority::Normal);
		USkylineGeckoEffectHandler::Trigger_OnPounceStart(Owner);
		GeckoComp.bCanDodge.Apply(false, this);

		Destination = GetTargetLocation();
		PounceDistance = Owner.ActorLocation.Dist2D(Destination);
		PounceDirection = ((Destination - Owner.ActorLocation) * FVector(1.0, 1.0, 0.0)) / PounceDistance;
		PounceSpeed = PounceDistance / Durations.Anticipation;
	}

	bool HasLanded()
	{
		if (Durations.IsBeforeAction(ActiveDuration))
			return false;
		if ((Owner.ActorLocation.Z > Destination.Z + 50.0) && (ActiveDuration < Durations.PreActionDuration + 0.5))
			return false;
		return true;
	}

	bool CanHit(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return false;
		if(!Player.ActorLocation.IsWithinDist(Owner.ActorLocation + Owner.ActorForwardVector * 20, Settings.PounceAttackHitRadius))
			return false;
		if(TargetConstrainComp.IsConstrained())
			return false;
		return true;	
	}

	bool CanConstrainTarget()
	{
		return false;
	// 	if (!CanHit(Target))
	// 		return false;
	// 	if (!TargetConstrainComp.CanConstrain())
	// 		return false;
	// #if TEST
	// 	if(Target.GetGodMode() == EGodMode::God)
	// 		return false;
	// #endif
	// 	return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbLand(bool bHitTarget, bool bConstrain)
	{
		if (Target == nullptr)
			return; // Target has been streamed out on remote, no need to carry this through

		bIsJumping = false;
		GeckoComp.bShouldLeap.Clear(this);

		// Note that currently pounce attack is a one-shot so this does nothing. Keep this in case we change it to a three-shot.
		AnimComp.RequestSubFeature(SubTagGeckoPounceAttack::Land, this);

		// Anticipation duration is time in jump, adjust to this
		Durations.Anticipation = ActiveDuration - Durations.Telegraph;

		// We're vulnerable now!		
		GeckoComp.bAllowBladeHits.Apply(true, this, EInstigatePriority::High);

		USkylineGeckoEffectHandler::Trigger_OnPounceLand(Owner);

		if (bHitTarget)
		{
			HitPlayer(Target);
		}

		if (CanHit(Target.OtherPlayer))
		{
			// On remote this'll only trigger effects
			HitPlayer(Target.OtherPlayer);
		}

		GeckoComp.StopTelegraph();

		if (GeckoComp.Team != nullptr)
		{
			// Only count attacks that hit or land within arena for team purposes
			// If a gecko has managed to get stuck just outside arena or under the stairs
			// it should be killed even if it tries to start attacks.
			if (bHitTarget || IsInsideArena())		
				GeckoComp.Team.LastAttackTime = Time::GameTimeSeconds;
		}
	}

	bool IsInsideArena()
	{
		FVector ArenaCenter = Arena.ArenaCenter.ActorLocation;
		if (!Math::IsWithin(Owner.ActorLocation.Z, ArenaCenter.Z - 20.0, ArenaCenter.Z + 200.0))
			return false;
		if (!Owner.ActorLocation.IsWithinDist2D(ArenaCenter, 1800.0)) 
			return false;

		// We're inside arena bounds, but might have gotten stuck below the stairs for some reason	
		FVector StairsCenter = ArenaCenter - Arena.ActorRightVector * 2200.0;
		if (Owner.ActorLocation.IsWithinDist2D(StairsCenter, 1500.0))
		{
			// We're in the stairs space and above arena floor, check if below stairs
			float StairsHeight = Math::GetMappedRangeValueClamped(FVector2D(1150.0, 1500.0), FVector2D(180.0, 20.0), Owner.ActorLocation.Dist2D(StairsCenter));
			if (Owner.ActorLocation.Z < ArenaCenter.Z + StairsHeight)
				return false;
		}
		return true;
	}

	void Recover()
	{
		bIsRecovering = true;
		GeckoComp.bCanDodge.Clear(this);
		USkylineGeckoEffectHandler::Trigger_OnPounceEnd(Owner);
	}

	private FVector GetTargetLocation() const
	{
		bool bHasTargetLoc = false;
		FVector ReturnLoc;
		FVector PathLoc;
		if (Pathfinding::FindNavmeshLocation(Target.ActorLocation, 600.0, 800.0, PathLoc))
		{
			ReturnLoc = PathLoc;
			bHasTargetLoc = true;
		}
		else
		{
			FHazeNavmeshPoly Poly = Navigation::FindNearestPoly(Target.ActorLocation, 2000.0);
			if (Poly.IsValid())
			{
				ReturnLoc = Poly.GetCenter() * 0.3 + Poly.GetClosestPointOnPoly(Owner.ActorLocation) * 0.7;
				bHasTargetLoc = true;
			}
		}
				
		if (bHasTargetLoc)
		{
			// If target location is too close to the arena bounds, offset the target location to the spline limits.
			FVector SplineLoc = Arena.ArenaBoundsSpline.Spline.GetClosestSplineWorldLocationToWorldLocation(Target.ActorLocation);
			SplineLoc.Z = ReturnLoc.Z;
			FVector CenterToSplineDir = (SplineLoc - Arena.ArenaCenter.ActorLocation).GetSafeNormal2D();
			FVector ReturnLocToSplineDir = (SplineLoc - ReturnLoc).GetSafeNormal2D();
			if (ReturnLocToSplineDir.DotProduct(CenterToSplineDir) < 0) // If outside of spline bounds, set to spline location.
				return SplineLoc;
			else
				return ReturnLoc;
		}

		return Owner.ActorLocation; 		
	}

	void HitPlayer(AHazePlayerCharacter Player)
	{
		USkylineGeckoEffectHandler::Trigger_OnPounceAttackHit(Owner, FSkylineGeckoEffectHandlerOnPounceData(Player));
		if (!Player.HasControl())
			return;
#if TEST
		if(Player.GetGodMode() == EGodMode::God)
			return;
#endif
		float Damage = Settings.PounceAttackDamagePlayer;
		Player.DealTypedDamage(Owner, Damage, EDamageEffectType::ObjectSmall, EDeathEffectType::ObjectSmall);

		FVector BackLoc = Owner.ActorLocation - PounceDirection * 40.0;		
		FVector ToTarget = Player.ActorLocation - BackLoc;
		FVector PushDir = PounceDirection;
		FVector SideDir = PounceDirection.CrossProduct(FVector::UpVector);
		if (PounceDirection.DotProduct(ToTarget) > 0.0)
		{
			// Push away and slightly to the side
			PushDir = ToTarget.GetNormalized2DWithFallback(Player.ActorRightVector);
			PushDir += SideDir * Math::RandRange(0.0, 0.2) * ((SideDir.DotProduct(ToTarget) > 0) ? 1.0 : -1.0);
		}
		else
		{
			// Push to the side	
			PushDir = SideDir;
			if (ToTarget.DotProduct(PushDir) < 0.0)
				PushDir = -SideDir;
		}
		Player.ApplyKnockdown(PushDir * Settings.PlayerKnockbackForce, Settings.PlayerKnockbackDuration);
	}
}