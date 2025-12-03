class USummitStoneBeastSlasherAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement); 
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	USummitStoneBeastSlasherSettings Settings;

	UGentlemanComponent TargetGentlemanComp;
	UGentlemanComponent SharedGentlemanComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USummitStoneBeastSlasherTentaclesComponent TentaclesComp;
	AHazeActor Target;
	FVector TargetLoc;
	FBasicAIAnimationActionDurations Durations;

	TArray<AHazePlayerCharacter> AvailableTargets;

	USummitStoneBeastSlasherTentacleDecalComponent DecalComp;
	FHazeAcceleratedFloat DecalWidth;
	float DecalLength;

	const FName SlasherAttackToken = n"SlasherAttackToken";
	const FName SlasherAttackSharedToken = n"SlasherAttackSharedToken";

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = USummitStoneBeastSlasherSettings::GetSettings(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		TentaclesComp = USummitStoneBeastSlasherTentaclesComponent::Get(Owner);
		SharedGentlemanComp = UGentlemanComponent::GetOrCreate(Game::Mio);
		DecalComp = USummitStoneBeastSlasherTentacleDecalComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && WantsToAttack() && !IsBlocked())
			GentCostQueueComp.JoinQueue(this);
		else
			GentCostQueueComp.LeaveQueue(this);
	}

	bool WantsToAttack() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.AttackRange))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!WantsToAttack())
			return false;
		if (TentaclesComp.Tentacles.Num() == 0)
			return false;
		if (!GentCostQueueComp.IsNext(this))
			return false;
		if (!TargetComp.GentlemanComponent.CanClaimToken(SlasherAttackToken, this))
			return false;
		if (!SharedGentlemanComp.CanClaimToken(SlasherAttackSharedToken, this))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Settings.AttackTelegraphDuration + Settings.AttackAnticipateDuration + Settings.AttackActionDuration + Settings.AttackRecoverDuration)
			return true;
		if (TentaclesComp.Tentacles.Num() == 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		Target = TargetComp.Target;
		TargetGentlemanComp = TargetComp.GentlemanComponent;

		TargetGentlemanComp.ClaimToken(SlasherAttackToken, this);
		SharedGentlemanComp.ClaimToken(SlasherAttackSharedToken, this);
		SharedGentlemanComp.ReleaseToken(SlasherAttackSharedToken, this, Settings.AttackSharedCooldown);

		Durations.Telegraph = Settings.AttackTelegraphDuration;
		Durations.Anticipation = Settings.AttackAnticipateDuration;
		Durations.Action = Settings.AttackActionDuration;
		Durations.Recovery = Settings.AttackRecoverDuration;
		TargetLoc = GetTelegraphLocation();
		AvailableTargets = Game::Players;

		DecalComp.SetHiddenInGame(false);
		DecalWidth.SnapTo(0.0);
		DecalLength = 0.0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(BasicSettings.AttackCooldown);
		TargetGentlemanComp.ReleaseToken(SlasherAttackToken, this, Settings.AttackPerPlayerCooldown);
		TargetComp.Target = nullptr;
		DecalComp.SetHiddenInGame(true);
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Durations.IsInTelegraphRange(ActiveDuration))
			TentacleTelegraph(DeltaTime);
		else if (Durations.IsInAnticipationRange(ActiveDuration))
			TentacleAnticipate(DeltaTime);
		else if (Durations.IsInActionRange(ActiveDuration))
			TentacleAttack(DeltaTime);
		else
			TentacleRecover(DeltaTime);

		FVector TentacleStart = TentaclesComp.Tentacles[0].AccNear.Value;
		FVector TentacleEnd = TentaclesComp.Tentacles[0].AccEnd.Value;
		if ((ActiveDuration > Durations.PreActionDuration) && (ActiveDuration < Durations.PreRecoveryDuration + 0.2))
		{
			for (int i = AvailableTargets.Num() - 1; i >= 0; i--)
			{
				if (!AvailableTargets[i].HasControl())
					continue;

				FVector LineLoc;
				float Dummy;
				FVector PlayerLoc = AvailableTargets[i].ActorCenterLocation;
				Math::ProjectPositionOnLineSegment(TentacleStart, TentacleEnd, PlayerLoc, LineLoc, Dummy);
				if (PlayerLoc.Z < LineLoc.Z - 150.0)
					continue; // Player is below	
				if (PlayerLoc.Z > LineLoc.Z + 50.0)
					continue; // Player is above	
				if (!PlayerLoc.IsWithinDist2D(LineLoc, 100.0))
					continue; // Player is away from line

				CrumbHit(AvailableTargets[i]);
			}
		}

		// Decal positioning and scaling
		// TODO: tentacle location accelerate into position so we need to keep updating after telegraph
		if (ActiveDuration < Durations.Telegraph + 0.1)
		{
			DecalLength = Math::Max(DecalLength, TentacleStart.Dist2D(TentacleEnd));			
			FVector DecalLoc = TentacleStart + (TentacleEnd - TentacleStart).GetSafeNormal2D() * DecalLength * 0.5;
			DecalLoc.Z = Owner.ActorLocation.Z + 100.0;
			DecalComp.SetWorldLocation(DecalLoc);
			DecalComp.SetWorldRotation(FRotator(0.0, (TentacleEnd - TentacleStart).Rotation().Yaw, 0.0));
		}
		if (Durations.IsInRecoveryRange(ActiveDuration))
			DecalWidth.AccelerateTo(0.0, Durations.Recovery, DeltaTime);
		else
			DecalWidth.AccelerateTo(1.0, Durations.Telegraph, DeltaTime);
		DecalComp.SetWorldScale3D(FVector(DecalLength * 0.004, DecalWidth.Value, 1.0));
	}

	UFUNCTION(CrumbFunction)
	void CrumbHit(AHazePlayerCharacter PlayerTarget)
	{
		PlayerTarget.DamagePlayerHealth(Settings.AttackDamage);
		AvailableTargets.Remove(PlayerTarget);
	}

	FVector GetTelegraphLocation()
	{
		FVector TargetDir = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal2D();
		float Reach = Math::Min(Settings.AttackRange + 200.0, Target.ActorLocation.Dist2D(Owner.ActorLocation) * 1.4);
		FVector TelegraphLoc = Owner.ActorLocation + TargetDir * Reach;
		TelegraphLoc.Z += 300.0;
		return TelegraphLoc;
	} 

	void TentacleTelegraph(float DeltaTime)
	{
		// Extend above and track target
		TargetLoc = GetTelegraphLocation();

		for (FSummitStoneBeastSlasherTentacle& Tentacle : TentaclesComp.Tentacles)
		{
			FVector Origin = TentaclesComp.WorldTransform.TransformPosition(Tentacle.LocalOrigin);
			FVector Fwd = TentaclesComp.WorldRotation.ForwardVector;
			Tentacle.AccEnd.SpringTo(TargetLoc, 4.0, 0.6, DeltaTime);
			FVector FarLoc = Origin + (TargetLoc - Origin) * 0.5;
			FarLoc.Z = TargetLoc.Z;
			Tentacle.AccFar.SpringTo(FarLoc, 6.0, 0.4, DeltaTime);
			FVector NearLoc = Origin + Fwd * 500.0;
			Tentacle.AccNear.SpringTo(NearLoc, 5.0, 0.5, DeltaTime);
			Tentacle.bBehaviourOverride = true;
		}
	}

	void TentacleAnticipate(float DeltaTime)
	{
		// Sudden jerk upwards in preparation for slamming down
		for (FSummitStoneBeastSlasherTentacle& Tentacle : TentaclesComp.Tentacles)
		{
			FVector Origin = TentaclesComp.WorldTransform.TransformPosition(Tentacle.LocalOrigin);
			FVector Fwd = TentaclesComp.WorldRotation.ForwardVector;
			FVector TargetDir = (TargetLoc - Origin).GetSafeNormal2D();
			Tentacle.AccEnd.SpringTo(TargetLoc + Fwd * 1000.0 - TargetDir * 800.0 , 50.0, 0.5, DeltaTime);
			FVector FarLoc = Origin + (TargetLoc - Origin) * 0.5;
			FarLoc.Z = TargetLoc.Z;
			Tentacle.AccFar.SpringTo(FarLoc, 6.0, 0.4, DeltaTime);
			FVector NearLoc = Origin + Fwd * 500.0;
			Tentacle.AccNear.SpringTo(NearLoc, 5.0, 0.5, DeltaTime);
			Tentacle.bBehaviourOverride = true;
		}
	}

	void TentacleAttack(float DeltaTime)
	{
		// Slash down to ground
		TargetLoc.Z = Owner.ActorLocation.Z + 10.0;
		for (FSummitStoneBeastSlasherTentacle& Tentacle : TentaclesComp.Tentacles)
		{
			FVector Origin = TentaclesComp.WorldTransform.TransformPosition(Tentacle.LocalOrigin);
			FVector Fwd = TentaclesComp.WorldRotation.ForwardVector;
			Tentacle.AccEnd.AccelerateTo(TargetLoc, Durations.Action * 0.5, DeltaTime);
			FVector FarLoc = Origin + (TargetLoc - Origin) * 0.5;
			Tentacle.AccFar.SpringTo(FarLoc, 200.0, 0.2, DeltaTime);
			FVector NearLoc = Origin + Fwd * 200.0;
			Tentacle.AccNear.SpringTo(NearLoc, 60.0, 0.5, DeltaTime);
			Tentacle.bBehaviourOverride = true;
		}
	}

	void TentacleRecover(float DeltaTime)
	{
		// Stay down a while before retreating to idle position
		for (FSummitStoneBeastSlasherTentacle& Tentacle : TentaclesComp.Tentacles)
		{
			FVector Origin = TentaclesComp.WorldTransform.TransformPosition(Tentacle.LocalOrigin);
			FVector Fwd = TentaclesComp.WorldRotation.ForwardVector;
			Tentacle.AccEnd.AccelerateTo(TargetLoc, Durations.Action * 0.5, DeltaTime);
			FVector FarLoc = Origin + (TargetLoc - Origin) * 0.5;
			Tentacle.AccFar.SpringTo(FarLoc, 200.0, 0.2, DeltaTime);
			FVector NearLoc = Origin + Fwd * 200.0;
			Tentacle.AccNear.SpringTo(NearLoc, 60.0, 0.5, DeltaTime);
			Tentacle.bBehaviourOverride = true;
		}
	}
};