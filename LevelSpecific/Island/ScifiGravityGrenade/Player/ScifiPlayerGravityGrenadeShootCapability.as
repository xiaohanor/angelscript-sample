class UScifiPlayerGravityGrenadeShootCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityGrenade");
	default CapabilityTags.Add(BlockedWhileIn::Swimming);
	
	default TickGroup = EHazeTickGroup::ActionMovement;
	default TickGroupOrder = 110;

	default DebugCategory = n"GravityGrenade";

	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	// Gravity Grenade Target
	UScifiPlayerGravityGrenadeManagerComponent Manager;
	UPlayerMovementComponent MoveComp;
	UPlayerAimingComponent AimingComp;
	UScifiPlayerGravityGrenadeSettings Settings;
	float DeactivationDuration = 0;
	bool bGravityGrenadeCharged = false;
	AScifiPlayerGravityGrenadeWeaponProjectile PendingProjectile;

	bool bHasFoundForcePullTarget;
	UScifiGravityGrenadeTargetableComponent ForcePullTarget;
	AScifiGravityGrenadeForcePull PreviousForcePullObject;
	float TimeLookingAtForcePullTarget = 0;
	float TimeRequiredToLookAtSameTarget = 0.6;
	AScifiGravityGrenadeForcePull FoundForcePullObject;
	float ForcePullMoveSpeedMultiplier = 0.4;
	
	UPlayerTargetablesComponent TargetContainer;

	// Force Grab
	bool bForceGrab = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerGravityGrenadeManagerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
		AimingComp = UPlayerAimingComponent::Get(Player);
		Settings = Manager.Settings;
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
	}
	
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FGravityGrenadeShootActivationParams& ActivationParam) const
	{
		if(!WasActionStarted(ActionNames::SecondaryLevelAbility))
			return false;

		//ActivationParam.Projectile = Manager.GetOrCreateControlSideProjectile();
		//ActivationParam.Target = Manager.CurrentTarget;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate(FGravityGrenadeShootActivationParams& ActivationParam) const
	{
		if(!IsActioning(ActionNames::SecondaryLevelAbility))
		{
			ActivationParam.Projectile = Manager.GetOrCreateControlSideProjectile();
			ActivationParam.Target = Manager.CurrentTarget;
			return true;
		}

		return false;
		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FGravityGrenadeShootActivationParams ActivationParam)
	{
		AimingComp.StartAiming(this, Manager.AimSettings);
		Player.Mesh.RequestOverrideFeature(n"GravityGrenade", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FGravityGrenadeShootActivationParams ActivationParam)
	{
		if(bHasFoundForcePullTarget)
		{
			auto ForcePullObject = Cast<AScifiGravityGrenadeForcePull>(ForcePullTarget.GetOwner());
			if(ForcePullObject != nullptr)
			{
				ForcePullObject.ForcePullStopped();
				MoveComp.ClearMoveSpeedMultiplier(this);

				for (AScifiGravityGrenadeForcePull ConnectedObject : ForcePullObject.ConnectedObjects)
				{
					ConnectedObject.ForcePullStopped();
				}
			}
			
			ForcePullTarget = nullptr;
			TimeLookingAtForcePullTarget = 0;
			PreviousForcePullObject = nullptr;
			bHasFoundForcePullTarget = false;
			
		Player.UnblockCapabilities(n"ShieldBuster", this);
		}

		if(bGravityGrenadeCharged)
		{
			PendingProjectile = ActivationParam.Projectile;

			FVector ThrowLocation = Manager.Weapon.GetActorLocation() + Player.Mesh.GetForwardVector() * 30.0;
			PendingProjectile.SetActorLocation(ThrowLocation);
			
			// A temp bonus pitch to have the projectiles not be destroyed when they hit the ground
			// when aiming down a lot. This is a TEMP fix. We need to make some nice
			// tracing to have the buster projectile follow the ground a bit.
			
			// FRotator ViewRotation = Player.GetViewRotation();
			// float BonusPitch = Math::Max(-ViewRotation.ForwardVector.DotProduct(MoveComp.WorldUp), 0);
			// BonusPitch = Math::Min(BonusPitch, 0.5) / 0.5;
			// ViewRotation += FRotator(Math::Lerp(9, 25, BonusPitch), 0.0, 0.0); // Offset the shoot direction a bit

			// Trace for impacts from camera to crosshair location 
			// Set direction of projectiles to from hands to impact location of line trace

			FHazeTraceSettings TraceProfile = Trace::InitChannel(ETraceTypeQuery::WeaponTraceZoe); //ETraceTypeQuery::   PlayerAiming WeaponTraceZoe
			TraceProfile.UseLine();
			TraceProfile.IgnoreActor(Game::Zoe);
			FRotator HudRotation = Player.GetViewRotation() + FRotator(6.5, 0.0, 0.0);
			FHitResult HitLocation = TraceProfile.QueryTraceSingle(Player.GetViewLocation() + HudRotation.ForwardVector*50.0, Player.GetViewLocation() + HudRotation.ForwardVector*3000.0);
			
			FVector ProjectileDirection(0.0, 0.0, 0.0);

			if(HitLocation.bBlockingHit)
				ProjectileDirection = (HitLocation.ImpactPoint - ThrowLocation).GetSafeNormal();

			else
				ProjectileDirection = ((Player.GetViewLocation() + HudRotation.ForwardVector*3000.0) - ThrowLocation).GetSafeNormal();

			PendingProjectile.MoveDirection = ProjectileDirection;
			PendingProjectile.LaunchTarget = ActivationParam.Target;
			PendingProjectile.CurrentMovementSpeed = Settings.Speed;

			// Trigger shoot event
			FScifiPlayerGravityGrenadeOnShootEventData ShootData;
			ShootData.Projectile = PendingProjectile;
			ShootData.HandLocation = ThrowLocation;
			ShootData.ShootDirection = PendingProjectile.GetWantedMovementDirection();
			UScifiPlayerGravityGrenadeEventHandler::Trigger_OnShoot(Player, ShootData);

			Manager.LastThrownDirection = PendingProjectile.GetWantedMovementDirection();
			Manager.LastShotGameTime = Time::GetGameTimeSeconds();

			// We need to wait a little bit for the throw animation
			if(PendingProjectile != nullptr)
			{
				PendingProjectile.SetActorLocationAndRotation(ThrowLocation, PendingProjectile.GetWantedMovementDirection().ToOrientationQuat());
				Manager.ActivateProjectile(PendingProjectile);
			}

			bGravityGrenadeCharged = false;
			Player.UnblockCapabilities(n"ShieldBuster", this);
		}

		AimingComp.StopAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		//LastActiveDeltaTime = DeltaTime;
		
		// if(!bGravityGrenadeCharged)
		// {
		// 	if(ActiveDuration > 0.6)
		// 	{
		// 		bGravityGrenadeCharged = true;
		// 		Player.BlockCapabilities(n"ShieldBuster", this);
		// 	}
		// }


		if(!bHasFoundForcePullTarget)
		{
			ForcePullTarget = TargetContainer.GetPrimaryTarget(UScifiGravityGrenadeTargetableComponent);

			if(ForcePullTarget != nullptr)
			{
				FoundForcePullObject = Cast<AScifiGravityGrenadeForcePull>(ForcePullTarget.GetOwner());
				if(FoundForcePullObject != nullptr)
				{
					if(PreviousForcePullObject == FoundForcePullObject)
					{
						TimeLookingAtForcePullTarget += DeltaTime;

						if(TimeLookingAtForcePullTarget >= TimeRequiredToLookAtSameTarget)
						{
							bHasFoundForcePullTarget = true;
							Player.BlockCapabilities(n"ShieldBuster", this);
							FoundForcePullObject.ForcePullStart();

							for (AScifiGravityGrenadeForcePull ConnectedObject : FoundForcePullObject.ConnectedObjects)
							{
								ConnectedObject.ForcePullStart();
							}

							MoveComp.ApplyMoveSpeedMultiplier(ForcePullMoveSpeedMultiplier, this, EInstigatePriority::High);
						}
					}

					else
					{
						PreviousForcePullObject = FoundForcePullObject;
						TimeLookingAtForcePullTarget = 0;
					}
				}
			}

			else
			{
				TimeLookingAtForcePullTarget = 0;
				PreviousForcePullObject = nullptr;
			}
		}

		else
		{
			TimeLookingAtForcePullTarget = 0;
			PreviousForcePullObject = nullptr;
		}
	}
}

struct FGravityGrenadeShootActivationParams
{
	AScifiPlayerGravityGrenadeWeaponProjectile Projectile;
	UScifiGravityGrenadeTargetableComponent Target;
}