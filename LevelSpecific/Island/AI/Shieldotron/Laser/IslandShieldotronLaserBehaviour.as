

class UIslandShieldotronLaserBehaviour : UBasicBehaviour

{

	default Requirements.Add(EBasicBehaviourRequirement::Weapon);



	UIslandShieldotronSettings Settings;

	UIslandShieldotronLaserAimingComponent AimingComp;

	UGentlemanCostComponent GentCostComp;

	UGentlemanCostQueueComponent GentCostQueueComp;

	UBasicAIHealthComponent HealthComp;



	FVector ScaledEndLocation;

	FVector LocalEndLocation;

	AAIIslandShieldotron Self;

	float DamageTime;

	float AttackStartedTime;

	

	const FName LaserToken = n"IslandShieldotronLaserToken";



	UFUNCTION(BlueprintOverride)

	void Setup()

	{

		Super::Setup();

		Settings = UIslandShieldotronSettings::GetSettings(Owner);

		AimingComp = UIslandShieldotronLaserAimingComponent::Get(Owner);

		Self = Cast<AAIIslandShieldotron>(Owner);

		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);

		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);

		HealthComp = UBasicAIHealthComponent::Get(Owner);

	}



	bool WantsToAttack() const

	{

		if (!Cooldown.IsOver())

			return false; 

		if (!Requirements.CanClaim(BehaviourComp, this))

			return false;

		if (!TargetComp.HasValidTarget())

			return false;

		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.LaserMaxActivationRange))

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

		if(!GentCostQueueComp.IsNext(this) && (Settings.LaserGentlemanCost != EGentlemanCost::None))

			return false;

		if(!GentCostComp.IsTokenAvailable(Settings.LaserGentlemanCost))

			return false;

		if (!TargetComp.GetGentlemanComponent().IsTokenAvailable(LaserToken))

			return false;

		if (IslandShieldotron::HasAnyPlayerClaimedToken(LaserToken, this))

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

		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.LaserTraceDistance))

			return true;

		if (AttackStartedTime + Settings.LaserDuration < Time::GameTimeSeconds)

			return true;



		return false;

	}



	UFUNCTION(BlueprintOverride)

	void OnActivated()

	{

		Super::OnActivated();

		GentCostComp.ClaimToken(this, Settings.LaserGentlemanCost);

		AimingComp.AimingLocation.StartLocation = Self.Laser.WorldLocation;

		DamageTime = 0;

		AttackStartedTime = Time::GameTimeSeconds;



		UGentlemanComponent GentlemanComp = TargetComp.GetGentlemanComponent();

		GentlemanComp.ClaimToken(LaserToken, this);

		

		// Update max num in runtime

		//GentlemanComp.SetMaxAllowedClaimants(LaserToken, Settings.LaserMaxNumAttackers);



		FVector Dir = Owner.ActorForwardVector.RotateAngleAxis(45, Owner.ActorRightVector).GetSafeNormal();		

		UpdateScaledEndLocation(Dir);

		FVector ScaledWorldEndLocation = AimingComp.AimingLocation.StartLocation + (Dir * AimingComp.AimingLocation.StartLocation.Distance(TargetComp.Target.ActorCenterLocation));

		FVector HitLocation;

		LaserTrace(Dir, HitLocation);

		LocalEndLocation = Owner.ActorTransform.InverseTransformPosition(ScaledWorldEndLocation);

	}



	UFUNCTION(BlueprintOverride)

	void OnDeactivated()

	{

		Super::OnDeactivated();

		GentCostComp.ReleaseToken(this);

		TargetComp.GetGentlemanComponent().ReleaseToken(LaserToken, this, Settings.LaserTeamCooldown);

		Cooldown.Set(Settings.LaserCooldown);

		AttackStartedTime = Time::GameTimeSeconds;

	}



	UFUNCTION(BlueprintOverride)

	void TickActive(float DeltaTime)

	{

		// Note: This is a somewhat peculiar way to do it. LocalEndLocation is being reset in every tick to transformed ScaledEndLocation. Could be simpler.



		// Update muzzle position since we might have moved since last tick

		AimingComp.AimingLocation.StartLocation = Self.Laser.WorldLocation;



		if(IsValidAngle(TargetComp.Target))

		{			

			UpdateLocalEndLocation(DeltaTime);

		}



		FVector WorldEndLocation = Owner.ActorTransform.TransformPosition(LocalEndLocation);



		// Check for hit and update effect

		FVector Dir = (WorldEndLocation - AimingComp.AimingLocation.StartLocation).GetSafeNormal();

		LaserTrace(Dir, WorldEndLocation);

		AimingComp.AimingLocation.EndLocation = WorldEndLocation; // for effect

		

		UpdateScaledEndLocation(Dir);

	}



	void LaserTrace(FVector Dir, FVector& HitLocation)

	{

		FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WeaponTraceEnemy);

		Trace.UseLine();

		Trace.IgnoreActor(Owner);

		HitLocation = AimingComp.AimingLocation.StartLocation + (Dir * Settings.LaserTraceDistance);

		FHitResult Hit = Trace.QueryTraceSingle(AimingComp.AimingLocation.StartLocation, HitLocation);

		if(Hit.bBlockingHit)

		{

			HitLocation = Hit.ImpactPoint;

			if(DamageTime == 0 || Time::GetGameTimeSince(DamageTime) > Settings.LaserDamageInterval)

			{

				auto Player = Cast<AHazePlayerCharacter>(Hit.Actor);

				if ((Player != nullptr) && Player.HasControl())

					DealDamage(Player, Hit);

				DamageTime = Time::GetGameTimeSeconds();

			}

		}

	}



	UFUNCTION(NotBlueprintCallable)

	private void DealDamage(AHazePlayerCharacter PlayerTarget, FHitResult Hit)

	{

		// Player damage is crumbed already

		auto ResponseComponent = UIslandProjectileResponseComponent::Get(PlayerTarget);

        if (ResponseComponent != nullptr)

            ResponseComponent.OnLaserHit.Broadcast(Hit.Location, Settings.LaserPlayerDamagePerSecond, Settings.LaserDamageInterval);

		else

			PlayerTarget.DealBatchedDamageOverTime(Settings.LaserPlayerDamagePerSecond * Settings.LaserDamageInterval, FPlayerDeathDamageParams());

	}



	// Scales EndLocation offset to distance from muzzle to target

	private void UpdateScaledEndLocation(FVector Dir)

	{		

		FVector ScaledWorldEndLocation = AimingComp.AimingLocation.StartLocation + (Dir * AimingComp.AimingLocation.StartLocation.Distance(TargetComp.Target.ActorCenterLocation));

		ScaledEndLocation = ScaledWorldEndLocation;

	}



	private void UpdateLocalEndLocation(float DeltaTime)

	{

		// Reset Local end location closer to muzzle

		LocalEndLocation = Owner.ActorTransform.InverseTransformPosition(ScaledEndLocation);



		FVector LocalTargetLocation = Owner.ActorTransform.InverseTransformPosition(TargetComp.Target.ActorCenterLocation);

		FVector LocalStartLocation = Owner.ActorTransform.InverseTransformPosition(AimingComp.AimingLocation.StartLocation);



		// Aim at a position slightly behind the target

		LocalTargetLocation += (LocalTargetLocation - LocalStartLocation).GetSafeNormal() * 100;



		// Move LocalEndLocation towards offset TargetLocation

		if(!LocalTargetLocation.IsWithinDist(LocalEndLocation, 15))

		{

			FVector Dir = (LocalTargetLocation - LocalEndLocation).GetSafeNormal();

			LocalEndLocation += Dir * DeltaTime * Settings.LaserFollowSpeed;

		}

		

	}



	private bool IsValidTarget(AHazePlayerCharacter Player)

	{

		if(!Player.OtherPlayer.ActorLocation.IsWithinDist(Owner.ActorLocation, Settings.LaserMaxActivationRange))

			return false;



		if(!IsValidAngle(Player))

			return false;



		return true;

	}



	private bool IsValidAngle(AHazeActor Target)

	{

		FVector Direction = (Target.ActorCenterLocation - Owner.ActorCenterLocation).ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();

		float Angle = Owner.ActorForwardVector.GetAngleDegreesTo(Direction);

		return Angle < Settings.LaserValidAngle;

	}

}