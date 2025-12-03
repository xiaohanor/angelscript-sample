// Commented out because it is not in use anyway and it caused a lot of Activations/Deactivations which lead to too many reliable net messages.
// class UIslandRedBlueSidescrollerLaserSightCapability : UHazePlayerCapability
// {
// 	// Since we don't want the crosshair to be hidden even if we block weapons for a bit, we don't have the below tag
// 	//default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueWeapon);
// 	default CapabilityTags.Add(IslandRedBlueWeapon::IslandRedBlueEquipped);
// 	default CapabilityTags.Add(CapabilityTags::GameplayAction);

// 	default CapabilityTags.Add(BlockedWhileIn::PoleClimb);
// 	default CapabilityTags.Add(BlockedWhileIn::Ladder);
// 	default CapabilityTags.Add(BlockedWhileIn::Swimming);

// 	default TickGroup = EHazeTickGroup::Input;
// 	default TickGroupOrder = 90;

// 	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

// 	UIslandRedBlueSidescrollerWeaponUserComponent SidescrollerWeaponUserComponent;
// 	UIslandRedBlueWeaponUserComponent WeaponUserComponent;
// 	UIslandRedBlueOverheatAssaultUserComponent OverheatComp;
// 	UPlayerTargetablesComponent TargetContainerComponent;
// 	UPlayerAimingComponent AimComponent;
// 	UIslandRedBlueSidescrollerAssaultSettings SidescrollerAssaultSettings;

// 	UPlayerAirDashComponent AirDashComp;
// 	UPlayerRollDashComponent RollDashComp;
// 	UPlayerStepDashComponent StepDashComp;
// 	UPlayerSlideDashComponent SlideDashComp;

// 	TArray<UNiagaraComponent> AimingLasers;

// 	FHazeAcceleratedVector AcceleratedLaserDirection;

// 	bool bLasersAreActive = false;
// 	const float LaserLength = 4000.0;

// 	UFUNCTION(BlueprintOverride)
// 	void Setup()
// 	{
// 		SidescrollerWeaponUserComponent = UIslandRedBlueSidescrollerWeaponUserComponent::Get(Player);
// 		WeaponUserComponent = UIslandRedBlueWeaponUserComponent::Get(Player);
// 		OverheatComp = UIslandRedBlueOverheatAssaultUserComponent::Get(Player);
// 		TargetContainerComponent = UPlayerTargetablesComponent::Get(Player);
// 		AimComponent = UPlayerAimingComponent::Get(Player);
// 		SidescrollerAssaultSettings = UIslandRedBlueSidescrollerAssaultSettings::GetSettings(Player);

// 		AirDashComp = UPlayerAirDashComponent::Get(Player);
// 		RollDashComp = UPlayerRollDashComponent::Get(Player);
// 		StepDashComp = UPlayerStepDashComponent::Get(Player);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldActivate() const
// 	{
// 		if(!WeaponUserComponent.HasEquippedWeapons())
// 			return false;

// 		if(!AimComponent.HasAiming2DConstraint())
// 			return false;

// 		if(!AimComponent.IsAiming(WeaponUserComponent))
// 			return false;

// 		if(OverheatComp.bIsOverheated
// 		&& OverheatComp.OverheatAlpha > 0)
// 			return false;

// 		if(AirDashComp.IsAirDashing())
// 			return false;

// 		if(RollDashComp.IsDashing())
// 			return false;

// 		if(StepDashComp.IsDashing())
// 			return false;
		
// 		if(WeaponUserComponent.WantsToFireWeapon())
// 			return true;

// 		if(Player.IsUsingGamepad())
// 		{
// 			if(!GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
// 				return true;
// 		}
		
// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	bool ShouldDeactivate() const
// 	{
// 		if(!WeaponUserComponent.HasEquippedWeapons())
// 			return true;

// 		if(!AimComponent.HasAiming2DConstraint())
// 			return true;

// 		if(!AimComponent.IsAiming(WeaponUserComponent))
// 			return true;

// 		if(OverheatComp.bIsOverheated
// 		&& OverheatComp.OverheatAlpha > 0)
// 			return true;

// 		if(AirDashComp.IsAirDashing())
// 			return true;

// 		if(RollDashComp.IsDashing())
// 			return true;

// 		if(StepDashComp.IsDashing())
// 			return true;

// 		if(Player.IsUsingGamepad())
// 		{
// 			if(GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
// 				return true;
// 		}

// 		return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated()
// 	{
// 		WeaponUserComponent.AimInstigators.Add(this);

// 		auto AimRay = AimComponent.GetPlayerAimingRay();
// 		auto PrimaryTarget = TargetContainerComponent.GetPrimaryTarget(UIslandRedBlueTargetableComponent);
// 		auto AimDir = GetAimDirection(AimRay, PrimaryTarget);

// 		AcceleratedLaserDirection.SnapTo(AimDir);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated()
// 	{
// 		WeaponUserComponent.AimInstigators.RemoveSingleSwap(this);
// 		ToggleLasers(false);
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{
// 		if(bLasersAreActive != ShouldShowLasers())
// 			ToggleLasers(ShouldShowLasers());

// 		auto AimRay = AimComponent.GetPlayerAimingRay();
// 		auto PrimaryTarget = TargetContainerComponent.GetPrimaryTarget(UIslandRedBlueTargetableComponent);
// 		auto TargetAimDir = GetAimDirection(AimRay, PrimaryTarget);

// 		AcceleratedLaserDirection.AccelerateTo(TargetAimDir, IslandRedBlueSidescrollerSettings::AimLaserAccelerationDuration, DeltaTime);

// 		if(bLasersAreActive)
// 		{
// 			UpdateLasers(AimRay);
// 		}
// 	}

// 	private void UpdateLasers(FAimingRay AimRay)
// 	{
// 		FHitResult LaserHit = TraceLaserHit(AimRay, 0.0);
// 		for(int i = 0; i < AimingLasers.Num(); i++)
// 		{
// 			UNiagaraComponent Laser = AimingLasers[i];
// 			FVector Start = LaserHit.TraceStart;
// 			FVector End = LaserHit.TraceEnd;

// 			if(LaserHit.bBlockingHit)
// 				End = LaserHit.ImpactPoint;
			
// 			FVector LaserEnd = End;
// 			if(IslandRedBlueSidescrollerSettings::bFadeOverShortDistance)
// 			{
// 				FVector DirToEnd = (End - Start).GetSafeNormal();
// 				LaserEnd = Start + DirToEnd * IslandRedBlueSidescrollerSettings::LaserFadeLength;
// 			}
// 			Laser.SetVectorParameter(n"LaserEnd", LaserEnd);
// 			Laser.SetVectorParameter(n"LaserHit", End);
// 		}
// 	}

// 	private FHitResult TraceLaserHit(FAimingRay AimRay, float AngleOffset)
// 	{
// 		FVector Start = AimRay.Origin;
// 		FVector Direction = AcceleratedLaserDirection.Value.GetSafeNormal();
// 		Direction = Direction.RotateAngleAxis(AngleOffset, Player.ActorRightVector);
// 		FVector End = Start + Direction * LaserLength;

// 		FHazeTraceSettings Trace;
// 		Trace.TraceWithChannel(ECollisionChannel::WeaponTracePlayer);
// 		Trace.UseLine();
// 		Trace.IgnorePlayers();

// 		for(auto Weapon : WeaponUserComponent.Weapons)
// 		{
// 			Trace.IgnoreActor(Weapon);
// 		}

// 		auto Hit = Trace.QueryTraceSingle(Start, End);

// 		TEMPORAL_LOG(Player, "Sidescroller Aim Laser")
// 			.HitResults("Obstacle Trace Result", Hit, FHazeTraceShape::MakeLine())
// 		;

// 		return Hit;
// 	}

// 	private FVector GetAimDirection(FAimingRay AimRay, UTargetableComponent PrimaryTarget) const
// 	{
// 		bool bIsUsingAutoAim = AimComponent.IsUsingAutoAim(WeaponUserComponent);

// 		FVector AimDir;		
// 		FVector Start = AimRay.Origin;
		
// 		if(!bIsUsingAutoAim || PrimaryTarget == nullptr)
// 			AimDir = AimRay.Direction;
// 		else
// 			AimDir = (PrimaryTarget.WorldLocation - Start).GetSafeNormal();

// 		if(AimDir.IsNearlyZero())
// 			AimDir = Player.ActorForwardVector;

// 		return AimDir;
// 	}

// 	private void ToggleLasers(bool bToggleOn)
// 	{
// 		if(bToggleOn)
// 		{
// 			if(bLasersAreActive)
// 				return;
			
// 			AimingLasers.Reset(2);
// 			SpawnLasers();

// 			for(auto Laser : AimingLasers)
// 			{
// 				Laser.Activate(true);
// 			}
// 			bLasersAreActive = true;
// 		}
// 		else
// 		{
// 			if(!bLasersAreActive)
// 				return;

// 			for(auto Laser : AimingLasers)
// 			{
// 				Laser.DeactivateImmediate();
// 			}
// 			bLasersAreActive = false;
// 		}
// 	}

// 	private void SpawnLasers()
// 	{
// 		for(auto Weapon : WeaponUserComponent.Weapons)
// 		{
// 			auto Laser = Niagara::SpawnLoopingNiagaraSystemAttached(SidescrollerWeaponUserComponent.SidescrollerAimLaserEffect, Weapon.Muzzle);
// 			AimingLasers.Add(Laser);
// 		}
// 	}

// 	bool ShouldShowLasers()
// 	{
// 		if(!WeaponUserComponent.HasWeaponsInHands())
// 			return false;

// 		if(!IslandRedBlueSidescrollerSettings::bHasLaserSight)
// 			return false;

// 		if(WeaponUserComponent.CurrentUpgradeType == EIslandRedBlueWeaponUpgradeType::SidescrollerAssault)
// 			return false;
		
// 		return true;
// 	}
// };