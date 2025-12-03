struct FIslandShieldotronLaserSweepActivationParams

{

	bool bSweepFromLeft = false;

}



class UIslandShieldotronLaserSweepBehaviour : UBasicBehaviour

{

	default Requirements.Add(EBasicBehaviourRequirement::Weapon);



	UIslandShieldotronSettings Settings;

	UIslandShieldotronLaserAimingComponent AimingComp;

	UGentlemanCostComponent GentCostComp;

	UGentlemanCostQueueComponent GentCostQueueComp;

	UBasicAIHealthComponent HealthComp;



	FVector ScaledEndLocation;

	FVector LocalEndLocation;

	FVector InitialTargetLocation;

	FVector DirEnd;

	FVector TargetEndLocation;

	AAIIslandShieldotron Self;

	float DamageTime;

	float AttackStartedTime;

	

	const FName LaserToken = n"IslandShieldotronLaserToken";



	bool bHasHitTarget = false;

	AHazeActor HitTarget;

	AHazeActor CurrentTarget;



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

	

	// TODO: check for HasControl? runs on both control and remote side but is only used in ShouldActivate on Control side?

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

		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.LaserMaxActivationRange))

			return false;

		if (Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, Settings.LaserMinActivationRange))

			return false;

		if (BasicSettings.RangedAttackRequireVisibility && !TargetComp.HasVisibleTarget())

			return false;

		return true;

	}



	UFUNCTION(BlueprintOverride)

	bool ShouldActivate(FIslandShieldotronLaserSweepActivationParams& ActivationParams) const

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



		ActivationParams.bSweepFromLeft = Math::RandBool();



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

		if (ScaledEndLocation.IsWithinDist(TargetEndLocation, 15) && !bHasHitTarget)

			return true;



		return false;

	}



	UFUNCTION(BlueprintOverride)

	void OnActivated(FIslandShieldotronLaserSweepActivationParams ActivationParams)

	{

		Super::OnActivated();

		GentCostComp.ClaimToken(this, Settings.LaserGentlemanCost);

		AimingComp.AimingLocation.StartLocation = Self.Laser.WorldLocation;

		AimingComp.AimingLocation.EndLocation = Self.Laser.WorldLocation; // Reset

		DamageTime = 0;

		AttackStartedTime = Time::GameTimeSeconds;



		CurrentTarget = TargetComp.Target;



		UGentlemanComponent GentlemanComp = TargetComp.GetGentlemanComponent();

		GentlemanComp.ClaimToken(LaserToken, this);

		// Update max num in runtime

		//GentlemanComp.SetMaxAllowedClaimants(LaserToken, Settings.LaserMaxNumAttackers);



		InitialTargetLocation = TargetComp.Target.ActorCenterLocation;

		float Sign = ActivationParams.bSweepFromLeft ? -1.0 : 1.0;

		FVector DirStart = Owner.ActorForwardVector.RotateAngleAxis(Sign * Settings.LaserHalfAngle, Owner.ActorUpVector).GetSafeNormal();

		DirStart = DirStart.RotateAngleAxis(10, Owner.ActorRightVector);

		

		DirEnd = Owner.ActorForwardVector.RotateAngleAxis(-Sign * Settings.LaserHalfAngle, Owner.ActorUpVector).GetSafeNormal();

		DirEnd = DirEnd.RotateAngleAxis(4, Owner.ActorRightVector);

		TargetEndLocation = AimingComp.AimingLocation.StartLocation + (DirEnd * AimingComp.AimingLocation.StartLocation.Distance(InitialTargetLocation));



		//Debug::DrawDebugLine(AimingComp.AimingLocation.StartLocation, AimingComp.AimingLocation.StartLocation + DirStart * 1800.0, Duration = 3.0);

		//Debug::DrawDebugLine(AimingComp.AimingLocation.StartLocation, AimingComp.AimingLocation.StartLocation + DirEnd * 1800.0, Duration = 3.0);

		UpdateScaledEndLocation(DirStart);

		FVector HitLocation;

		LaserTrace(DirStart, HitLocation);

		LocalEndLocation = Owner.ActorTransform.InverseTransformPosition(ScaledEndLocation);

		AnimComp.RequestFeature(FeatureTagIslandSecurityMech::LaserShot, EBasicBehaviourPriority::Medium, this);



		// Init aim yaw

		FVector XYPlaneDir = DirStart.ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();

		float YawAngle = FRotator::MakeFromX(XYPlaneDir).Yaw;

		AnimComp.AimYaw.Apply(YawAngle, this);

	}



	UFUNCTION(BlueprintOverride)

	void OnDeactivated()

	{

		Super::OnDeactivated();

		if (TargetComp.HasValidTarget())

		{

			GentCostComp.ReleaseToken(this);

			TargetComp.GetGentlemanComponent().ReleaseToken(LaserToken, this, Settings.LaserTeamCooldown);

		}

		Cooldown.Set(Settings.LaserCooldown);

		AttackStartedTime = Time::GameTimeSeconds;

		bHasHitTarget = false;

		HitTarget = nullptr;

		CurrentTarget = nullptr;

		AnimComp.AimYaw.Clear(this);

	}



	UFUNCTION(BlueprintOverride)

	void TickActive(float DeltaTime)

	{

		if (ActiveDuration < Settings.LaserTelegraphDuration)

			return;



		// Update muzzle position since we might have moved since last tick

		AimingComp.AimingLocation.StartLocation = Self.Laser.WorldLocation;



		if(IsValidAngle(CurrentTarget))

		{			

			UpdateLocalEndLocation(DeltaTime);

		}





		FVector WorldEndLocation = Owner.ActorTransform.TransformPosition(LocalEndLocation);



		// Check for hit and update effect

		FVector Dir = (WorldEndLocation - AimingComp.AimingLocation.StartLocation).GetSafeNormal();

		LaserTrace(Dir, WorldEndLocation);

		AimingComp.AimingLocation.EndLocation = WorldEndLocation; // for effect

		

		UpdateScaledEndLocation(Dir);



		// Update aiming animation yaw angle (The xy-angle between forward vector and laser)

		FVector XYPlaneDir = Dir.ConstrainToPlane(Owner.ActorUpVector).GetSafeNormal();

		float YawAngle = FRotator::MakeFromX(XYPlaneDir).Yaw;

		AnimComp.AimYaw.Apply(YawAngle, this);

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

				if (Player != nullptr && Player.HasControl())

				{

					if (HitTarget != Player)

					{

						if (HasControl())

							CrumbSetHitTarget(Player, Time::GetGameTimeSeconds());

						else

							CrumbSetHitTargetFromRemote(Player, Time::GetGameTimeSeconds());

					}

					if (HasControl()) // only update timestamp on own control side

						CurrentHitTimeStamp = Time::GetGameTimeSeconds();

					DealDamage(Player, Hit);

					DamageTime = Time::GetGameTimeSeconds();

				}

			}

		}

	}



	float CurrentHitTimeStamp;

	UFUNCTION(CrumbFunction)

	void CrumbSetHitTarget(AHazeActor Target, float TimeStamp)

	{

		if (CurrentHitTimeStamp > TimeStamp) // old message

			return;

		

		bHasHitTarget = true;

		HitTarget = Target;

		CurrentHitTimeStamp = TimeStamp;

	}



	UFUNCTION(CrumbFunction)

	void CrumbSetHitTargetFromRemote(AHazeActor Target, float TimeStamp)

	{

		if (CurrentHitTimeStamp > TimeStamp) // old message

		{

			// Control corrects remote side 

			if (HasControl() && bHasHitTarget)

				CrumbSetHitTarget(HitTarget, Time::GetGameTimeSeconds());

			return;

		}



		bHasHitTarget = true;

		HitTarget = Target;

		CurrentHitTimeStamp = TimeStamp;

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



	private void UpdateScaledEndLocation(FVector Dir)

	{

		ScaledEndLocation =  AimingComp.AimingLocation.StartLocation + (Dir * AimingComp.AimingLocation.StartLocation.Distance(InitialTargetLocation));

	}



	private void UpdateLocalEndLocation(float DeltaTime)

	{

		LocalEndLocation = Owner.ActorTransform.InverseTransformPosition(ScaledEndLocation);

		

		FVector LocalTargetLocation = Owner.ActorTransform.InverseTransformPosition(TargetEndLocation);

		if (bHasHitTarget)

			LocalTargetLocation = Owner.ActorTransform.InverseTransformPosition(HitTarget.ActorCenterLocation);

		

			

		FVector LocalStartLocation = Owner.ActorTransform.InverseTransformPosition(AimingComp.AimingLocation.StartLocation);



		//FVector ToTargetDir = (LocalTargetLocation - LocalStartLocation).GetSafeNormal();

		//FVector SideDir = ToTargetDir.CrossProduct(FVector::UpVector);

		

		// Aim at a position slightly behind the target			

		//LocalTargetLocation -= ToTargetDir * 100;

		//LocalTargetLocation += LocalTargetLocation + SideDir * 100;

		

		// Move LocalEndLocation towards offset TargetLocation

		if(!LocalTargetLocation.IsWithinDist(LocalEndLocation, 15))

		{

			FVector Dir = (LocalTargetLocation - LocalEndLocation).GetSafeNormal();

			LocalEndLocation += Dir * DeltaTime * Settings.LaserFollowSpeed * 2;

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