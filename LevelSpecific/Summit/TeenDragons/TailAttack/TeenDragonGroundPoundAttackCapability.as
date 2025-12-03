class UTeenDragonGroundPoundAttackCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);	
	default CapabilityTags.Add(n"TeenDragon");
	default CapabilityTags.Add(n"GroundPoundAttack");

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 20;

	//ATeenDragon TeenDragon;
	//AHazePlayerCharacter Player;
	UPlayerTailTeenDragonComponent DragonComp;
	UHazeMovementComponent MoveComp;

	USteppingMovementData Movement;
	bool bLanded = false;
	bool bDiving = false;
	float AttackTimer = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		//TeenDragon = Cast<ATeenDragon>(Owner);
		//Player = TeenDragon.Player;
		DragonComp = UPlayerTailTeenDragonComponent::Get(Player);

		MoveComp = UHazeMovementComponent::Get(Owner);
		Movement = MoveComp.SetupSteppingMovementData();
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		// if (DragonComp.IsRolling())
		// 	return false;
		if (!WasActionStarted(ActionNames::PrimaryLevelAbility))
			return false;
		if (!MoveComp.IsInAir())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (bLanded && AttackTimer >= TeenDragonGroundPoundAttack::AttackDuration)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(n"GameplayAction", this);
		Player.BlockCapabilities(n"Movement", this);

		DragonComp.AnimationState.Apply(ETeenDragonAnimationState::GroundPoundAttackDive, this);
		UTeenDragonGroundPoundAttackEventHandler::Trigger_GroundPoundAttackTriggered(Player);

		bLanded = false;
		bDiving = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(n"GameplayAction", this);
		Player.UnblockCapabilities(n"Movement", this);

		DragonComp.AnimationState.Clear(this);
		UTeenDragonGroundPoundAttackEventHandler::Trigger_GroundPoundAttackEnded(Player);
	}

	UFUNCTION(CrumbFunction)
	void CrumbPerformAttack(TArray<UTeenDragonTailAttackResponseComponent> HitComponents)
	{
		for (UTeenDragonTailAttackResponseComponent ResponseComp : HitComponents)
		{
			FGroundPoundAttackParams HitParams;
			HitParams.AreaCenterLocation = Player.ActorLocation;
			HitParams.AreaRadius = TeenDragonGroundPoundAttack::AttackRadius;
			HitParams.DamageDealt = TeenDragonGroundPoundAttack::AttackDamage;
			HitParams.PlayerInstigator = Player;

			ResponseComp.OnHitByGroundPoundAttack.Broadcast(HitParams);

			FTeenDragonGroundPoundAttackImpactParams EffectParams;
			EffectParams.AttackAreaCenter = Player.ActorLocation;
			EffectParams.ImpactType = ResponseComp.ImpactType;
			EffectParams.HitComponent = ResponseComp;

			UTeenDragonGroundPoundAttackEventHandler::Trigger_AttackAreaImpact(Player, EffectParams);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Start diving after the delay
		if (!bDiving && ActiveDuration > TeenDragonGroundPoundAttack::DiveDelay)
		{
			Player.SetActorVelocity(FVector(0.0, 0.0, -TeenDragonGroundPoundAttack::DiveInitialSpeed));
			Player.PlayCameraShake(DragonComp.GroundPoundAttackDiveCameraShake, this); 
			UTeenDragonGroundPoundAttackEventHandler::Trigger_GroundPoundDiveStarted(Player);
		
			bDiving = true;
		}

		if (MoveComp.PrepareMove(Movement))
		{
			if (HasControl())
			{
				if (bLanded)
				{
					Movement.AddOwnerVerticalVelocity();
					Movement.AddGravityAcceleration();
				}
				else if (bDiving)
				{
					FVector VerticalVelocity = MoveComp.VerticalVelocity;
					VerticalVelocity.Z -= TeenDragonGroundPoundAttack::DiveAcceleration * DeltaTime;
					VerticalVelocity.Z = Math::Min(VerticalVelocity.Z, TeenDragonGroundPoundAttack::DiveMaxSpeed);

					Movement.AddVerticalVelocity(VerticalVelocity);
				}
			}
			// Remote
			else
			{
				Movement.ApplyCrumbSyncedGroundMovement();
			}

			MoveComp.ApplyMove(Movement);
			DragonComp.RequestLocomotionDragonAndPlayer(n"GroundPoundAttack");
		}

		// When we've landed, do the attack
		if (!bLanded && !MoveComp.IsInAir())
		{
			bLanded = true;

			DragonComp.AnimationState.Apply(ETeenDragonAnimationState::GroundPoundAttackLanded, this);
			Player.PlayCameraShake(DragonComp.GroundPoundAttackLandCameraShake, this); 
			UTeenDragonGroundPoundAttackEventHandler::Trigger_GroundPoundLanded(Player);

			AttackTimer = 0.0;

			TArray<UTeenDragonTailAttackResponseComponent> HitComponents;

			FHazeTraceSettings Trace;
			Trace.UseSphereShape(TeenDragonGroundPoundAttack::AttackRadius);
			Trace.TraceWithChannel(ECollisionChannel::WeaponTraceZoe);
			Trace.IgnorePlayers();

			FOverlapResultArray OverlapHits = Trace.QueryOverlaps(Player.ActorLocation);
			for (FOverlapResult Overlap : OverlapHits)
			{
				if (Overlap.Actor == nullptr)
					continue;

				auto ResponseComp = UTeenDragonTailAttackResponseComponent::Get(Overlap.Actor);
				if (ResponseComp != nullptr)
					HitComponents.Add(ResponseComp);
			}

			CrumbPerformAttack(HitComponents);
		}

		if (bLanded)
		{
			AttackTimer += DeltaTime;
		}
	}
}