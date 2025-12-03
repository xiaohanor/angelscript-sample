class UScifiPlayerCopsGunPickTargetCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunTargetPicking");
	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);

	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	
	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	UScifiPlayerCopsGunSettings Settings;
	UScifiPlayerCopsGunManagerComponent Manager;
	UScifiCopsGunInternalEnvironmentThrowTargetableComponent EnvironmentTarget;
	UPlayerTargetablesComponent TargetContainer;

	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;
	ACopsGunTurret Turret;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
		Settings = Manager.Settings;
		EnvironmentTarget = Manager.InternalEnvironmentTarget;

		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		Turret = Manager.Turret;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!HasControl())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!HasControl())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		CrumbSetShootAtTarget(nullptr);
		CrumbSetThrowAtTarget(nullptr);
		EnvironmentTarget.bIsAutoAimEnabled = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		const bool bHasWeapons = Manager.WeaponsAreAttachedToPlayer();

		// Start by clearing everything so the functions can find new ones
		//Manager.CurrentThrowTargetPoint = nullptr;
		EnvironmentTarget.bIsAutoAimEnabled = false;

		UScifiCopsGunShootTargetableComponent WantedShootAtTarget = nullptr;
		UScifiCopsGunThrowTargetableComponent WantedThrowAtTarget = Manager.CurrentThrowTargetPoint;

		// Update the weapon targets
		if(CanActivateOnWeapon(LeftWeapon) && CanActivateOnWeapon(RightWeapon))
		{
			bool bHasBlockedThrowing = false;
			bool bHasBlockedShootTargets = false;
			
			if(bHasWeapons)
			{
				if(!bHasBlockedShootTargets)
					WantedShootAtTarget = QueryShootAtTarget();

				if(!bHasBlockedThrowing)
					WantedThrowAtTarget = QueryThrowableTarget();
			}
			else
			{
				WantedShootAtTarget = QueryFreeWeaponShootAtTarget();
			}
		}
		else if(Manager.bTurretIsActive && Turret.IsAttachedToWeaponPoint())
		{		
			WantedShootAtTarget = QueryFreeWeaponShootAtTarget();
		}

		if(WantedShootAtTarget != Manager.CurrentShootAtTarget)
			CrumbSetShootAtTarget(WantedShootAtTarget);

		if(WantedThrowAtTarget != Manager.CurrentThrowTargetPoint)
			CrumbSetThrowAtTarget(WantedThrowAtTarget);
	}

	bool CanActivateOnWeapon(AScifiCopsGun Weapon) const
	{
		if(Weapon.IsWeaponBlocked())
			return false;

		if(Weapon.CurrentState == EScifiPlayerCopsGunState::MovingToTarget)
			return false;
	
		return true;
	}

	UScifiCopsGunShootTargetableComponent QueryShootAtTarget() const
	{
		return TargetContainer.GetPrimaryTarget(UScifiCopsGunShootTargetableComponent);
	}

	UScifiCopsGunShootTargetableComponent QueryFreeWeaponShootAtTarget() const
	{
	 	TArray<UTargetableComponent> Targetables;
	 	TargetContainer.GetRegisteredTargetables(UScifiCopsGunShootTargetableComponent, Targetables);

		UScifiCopsGunShootTargetableComponent BestTarget = nullptr;
		float BestScore = -1;
		for(auto Target : Targetables)
		{
			auto ItShootAtTarget = Cast<UScifiCopsGunShootTargetableComponent>(Target);

			float TargetScore = -1;
			if(!ItShootAtTarget.CheckWeaponTargetable(Manager, BestScore, TargetScore))
				continue;

			if(TargetScore < BestScore)
				continue;

			BestTarget = ItShootAtTarget;
			BestScore = TargetScore;
		}

		return Cast<UScifiCopsGunShootTargetableComponent>(BestTarget);	
	}

	UScifiCopsGunThrowTargetableComponent QueryThrowableTarget() const
	{
		if(Manager.bPlayerWantsToThrowWeapon)
		{
			// Trace for the environment impacts
			auto WallTraceSettings = Manager.InitCopsGunTrace();
			//WallTraceSettings.DebugDrawOneFrame();

			FVector UpVector = Player.MovementWorldUp;

			// Offset for the crosshair;
			FVector CrossHairOffset = UpVector * 45.0;
			FRotator ViewRotation = Player.GetViewRotation();
			ViewRotation += FRotator(8.0, 0.0, 0.0); 
	
			FVector TraceFrom = Player.GetActorLocation() + (UpVector * Player.CapsuleComponent.GetScaledCapsuleHalfHeight() * 2) + CrossHairOffset;
			FVector TraceTo = TraceFrom + (ViewRotation.ForwardVector * Settings.ThrowAtEnvironmentDistance);
			FHitResult HitResult = Manager.QueryTrace(WallTraceSettings, TraceFrom, TraceTo);

			bool bIsValidImpact = HitResult.bBlockingHit && !HitResult.bStartPenetrating;
			if(Settings.bOnlyAllowWallEnvironment)
				bIsValidImpact = bIsValidImpact && HitResult.ImpactNormal.DotProduct(Player.MovementWorldUp) < 0.5;

			if(bIsValidImpact)
			{
				auto ThrowableTarget = UScifiCopsGunThrowTargetableComponent::Get(HitResult.Actor);
				if(ThrowableTarget != nullptr)
				{
					bIsValidImpact = false;
				}
			}
			
			if(bIsValidImpact)
			{
				EnvironmentTarget.bIsAutoAimEnabled = true;

				if(!EnvironmentTarget.IsAttachedTo(HitResult.Component))
					EnvironmentTarget.AttachTo(HitResult.Component);
				
				EnvironmentTarget.SetWorldLocation(HitResult.ImpactPoint);
				EnvironmentTarget.SetWorldRotation((HitResult.ImpactNormal).ToOrientationRotator());
				EnvironmentTarget.CustomStayAtTargetTime = Settings.StayAtWallImpactMaxTime;
			}
			else if(EnvironmentTarget.bIsAutoAimEnabled)
			{
				EnvironmentTarget.bIsAutoAimEnabled = false;
				EnvironmentTarget.AttachTo(Player.Mesh);	
			}
		}
		
		return TargetContainer.GetPrimaryTarget(UScifiCopsGunThrowTargetableComponent);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetShootAtTarget(UScifiCopsGunShootTargetableComponent NewTarget)
	{
		Manager.CurrentShootAtTarget = NewTarget;
		LeftWeapon.SetShootAtTarget(NewTarget);
		RightWeapon.SetShootAtTarget(NewTarget);
	}

	UFUNCTION(CrumbFunction)
	void CrumbSetThrowAtTarget(UScifiCopsGunThrowTargetableComponent NewTarget)
	{
		Manager.CurrentThrowTargetPoint = NewTarget;
	}
};