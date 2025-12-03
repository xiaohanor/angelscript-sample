
class UIslandBuzzerLaserBehaviour : UBasicBehaviour
{
	default CapabilityTags.Add(BasicAITags::Attack);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);

	UIslandBuzzerSettings BuzzerSettings;
	UIslandBuzzerLaserAimingComponent AimingComp;
	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	USceneComponent Laser;

	FVector EndLocation;
	FVector LocalEndLocation;
	float DamageTime;
	float TargetObstructionRange;
	float ObstructionRange;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		BuzzerSettings = UIslandBuzzerSettings::GetSettings(Owner);
		AimingComp = UIslandBuzzerLaserAimingComponent::Get(Owner);
		Laser = USceneComponent::Get(Owner, n"Laser");
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BuzzerSettings.LaserRange))
			return false;
		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Super::ShouldActivate() == false)
			return false;
		if (!WantsToAttack())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(BuzzerSettings.LaserGentlemanCost))
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(!TargetComp.HasValidTarget())
			return true;
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, BuzzerSettings.LaserRange))
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, BuzzerSettings.LaserGentlemanCost);
		AimingComp.AimingLocation.StartLocation = Laser.WorldLocation;
		DamageTime = 0.0;

		FVector Dir = Owner.ActorForwardVector.RotateAngleAxis(45.0, Owner.ActorRightVector).GetSafeNormal();
		FVector HitLocation;
		LaserTrace(Dir, HitLocation);
		ObstructionRange = TargetObstructionRange;
		EndLocation = GetEndLocation(Dir);
		LocalEndLocation = Owner.ActorTransform.InverseTransformPosition(EndLocation);
		UIslandBuzzerEffectHandler::Trigger_OnStartedLaser(Owner, FIslandBuzzerAimingEventData(AimingComp));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		UIslandBuzzerEffectHandler::Trigger_OnStoppedLaser(Owner);
		GentCostComp.ReleaseToken(this);
		Cooldown.Set(2);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AimingComp.AimingLocation.StartLocation = Laser.WorldLocation;

		LocalEndLocation = GetLocalEndLocation(DeltaTime);

		FVector WorldEndLocation = Owner.ActorTransform.TransformPosition(LocalEndLocation);
		FVector Dir = (WorldEndLocation - AimingComp.AimingLocation.StartLocation).GetSafeNormal();
		LaserTrace(Dir, WorldEndLocation);
	 	if (TargetObstructionRange < ObstructionRange)
		 	ObstructionRange = TargetObstructionRange; // Cut short immediately
		else
			ObstructionRange = Math::Lerp(ObstructionRange, TargetObstructionRange, 4.0 * DeltaTime); // Lengthen over time (quickly)
		EndLocation = GetEndLocation(Dir);
		AimingComp.AimingLocation.EndLocation = EndLocation;
	}

	void LaserTrace(FVector Dir, FVector& HitLocation)
	{
		if (ActiveDuration < DamageTime)
			return;
		DamageTime = ActiveDuration + BuzzerSettings.LaserDamageInterval;

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);
		Trace.UseLine();
		Trace.IgnoreActor(Owner);
		HitLocation = AimingComp.AimingLocation.StartLocation + (Dir * BuzzerSettings.LaserTraceDistance);
		FHitResult Hit = Trace.QueryTraceSingle(AimingComp.AimingLocation.StartLocation, HitLocation);
		if(Hit.bBlockingHit)
		{
			HitLocation = Hit.ImpactPoint;
			auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);
			if ((Player != nullptr) && Player.HasControl())
				DealDamage(Player, Dir);
		}

		TargetObstructionRange = AimingComp.AimingLocation.StartLocation.Distance(HitLocation);		
	}

	private void DealDamage(AHazePlayerCharacter PlayerTarget, FVector Direction)
	{
		// Player damage is crumbed already, other sideeffects are ok to desync
		PlayerTarget.DealTypedDamageBatchedOverTime(Owner ,BuzzerSettings.LaserPlayerDamagePerSecond * BuzzerSettings.LaserDamageInterval, EDamageEffectType::LaserSoft, EDeathEffectType::LaserSoft);
		PlayerTarget.ApplyAdditiveHitReaction(Direction, EPlayerAdditiveHitReactionType::Small);
		UPlayerDamageEventHandler::Trigger_TakeDamageOverTime(PlayerTarget);
	}

	private FVector GetEndLocation(FVector Dir)
	{
		return AimingComp.AimingLocation.StartLocation + (Dir * ObstructionRange);
	}

	private FVector GetLocalEndLocation(float DeltaTime)
	{
		FVector EndLoc = LocalEndLocation;
		if(IsValidAngle(TargetComp.Target))
		{
			EndLoc = Owner.ActorTransform.InverseTransformPosition(EndLocation);
			FVector LocalTargetLocation = Owner.ActorTransform.InverseTransformPosition(TargetComp.Target.ActorCenterLocation);
			FVector LocalStartLocation = Owner.ActorTransform.InverseTransformPosition(AimingComp.AimingLocation.StartLocation);

			// Aim at a position slightly behind the target
			LocalTargetLocation += (LocalTargetLocation - LocalStartLocation).GetSafeNormal() * 100;

			if(!LocalTargetLocation.IsWithinDist(LocalEndLocation, 15))
			{
				FVector Dir = (LocalTargetLocation - LocalEndLocation).GetSafeNormal();
				EndLoc += Dir * DeltaTime * BuzzerSettings.LaserFollowSpeed;
			}
		}
		return EndLoc;
	}

	private bool IsValidTarget(AHazePlayerCharacter Player)
	{
		if(!Player.OtherPlayer.ActorLocation.IsWithinDist(Owner.ActorLocation, BuzzerSettings.LaserRange))
			return false;

		if(!IsValidAngle(Player))
			return false;

		return true;
	}

	private bool IsValidAngle(AHazeActor Target)
	{
		FVector Direction = (Target.ActorCenterLocation - Owner.ActorCenterLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();
		float Angle = Owner.ActorForwardVector.GetAngleDegreesTo(Direction);
		return Angle < BuzzerSettings.LaserValidAngle;
	}
}