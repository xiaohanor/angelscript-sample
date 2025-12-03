
class UScifiPlayerCopsGunManagerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"CopsGun");
	default CapabilityTags.Add(n"CopsGunManager");
	default CapabilityTags.Add(CombatBlockedWhileIn::GloryKill);

	default DebugCategory = n"CopsGun";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UScifiPlayerCopsGunManagerComponent Manager;
	UPlayerTargetablesComponent TargetContainer;
	UScifiPlayerCopsGunSettings Settings;
	AScifiCopsGun LeftWeapon;
	AScifiCopsGun RightWeapon;
	bool bHasActuallyTriggerdOverheat = false;

	#if !RELEASE
	UHazeImmediateDrawer DebugDrawer;
	#endif

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerCopsGunManagerComponent::Get(Player);
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
		Settings = Manager.Settings;
		
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
		LeftWeapon.AddActorDisable(this);
		RightWeapon.AddActorDisable(this);
		Manager.AttachWeaponToPlayerThigh(LeftWeapon, this);
		Manager.AttachWeaponToPlayerThigh(RightWeapon, this);
		LeftWeapon.bHasReachedMoveToTarget = true;
		RightWeapon.bHasReachedMoveToTarget = true;
	
		#if !RELEASE
		DebugDrawer = DevMenu::RequestImmediateDevMenu(n"CopsGun", "🏹");
		#endif
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		LeftWeapon.RemoveActorDisable(this);
		//LeftWeapon.BulletsLeftToReload = Settings.MagCapacity;

		RightWeapon.RemoveActorDisable(this);
		//RightWeapon.BulletsLeftToReload = Settings.MagCapacity;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		LeftWeapon.AddActorDisable(this);
		RightWeapon.AddActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Shooting
		if(!Manager.bPlayerIsShooting)
		{
			if(LeftWeapon.bIsShooting || RightWeapon.bIsShooting)
			{
				Manager.bPlayerIsShooting = true;
				UScifiPlayerCopsGunEventHandler::Trigger_OnShootStarted(Player);
			}
		}
		else
		{
			if(!LeftWeapon.bIsShooting && !RightWeapon.bIsShooting)
			{
				Manager.bPlayerIsShooting = false;
				UScifiPlayerCopsGunEventHandler::Trigger_OnShootStopped(Player);
			}
		}

		// Overheat
		if(!bHasActuallyTriggerdOverheat && Manager.HasTriggeredOverheat())
		{
			bHasActuallyTriggerdOverheat = true;
			FScifiPlayerCopsGunOverheatData OverheatEffectData;
			OverheatEffectData.TimeUntilWeStartTheCooldown = Settings.OverheatCooldownDelayTime;
			OverheatEffectData.CooldownTime = Settings.OverheatCooldownTime;
			UScifiPlayerCopsGunEventHandler::Trigger_OnOverheat(Player, OverheatEffectData);
		}
		else if(bHasActuallyTriggerdOverheat && !Manager.HasTriggeredOverheat())
		{
			bHasActuallyTriggerdOverheat = false;
		}

		// Update the bullet movement locally and apply impacts or lifetime
		{
			TArray<FScifiCopsGunReplicatedImpactResponseData> ReplicatedImpacts;
			for (int i = Manager.ActiveBullets.Num() - 1; i >= 0; --i)
			{
				auto Bullet = Manager.ActiveBullets[i];
				Bullet.Move(DeltaTime);

				if (Bullet.HasImpact())
				{	
					Manager.ApplyBulletImpactEffect(Bullet.MovementImpact);

					// Replicate important impacts
					auto ResponseComp = UScifiCopsGunImpactResponseComponent::Get(Bullet.MovementImpact.Actor);
					if (ResponseComp != nullptr)
					{
						FScifiCopsGunReplicatedImpactResponseData Replication;
						Replication.ResponseComponent = ResponseComp;
						Replication.RelativeImpactLocation = Bullet.MovementImpact.Actor.GetActorTransform().InverseTransformPosition(Bullet.MovementImpact.ImpactLocation);
						ReplicatedImpacts.Add(Replication);
					}

					Manager.DeactiveBulletAtActiveIndex(i);
			
				}
				else if(Time::GetGameTimeSince(Bullet.ActivationTime) > 5)
				{
					Manager.DeactiveBulletAtActiveIndex(i);	
				}
			}

			// We only replicate from the control side
			if(HasControl() && ReplicatedImpacts.Num() > 0)
			{
				CrumbReplicateImpacts(ReplicatedImpacts);
			}
		}	

		// Apply all new impacts
		{
			for(auto NewImpact : Manager.PendingBulletImpactsResponse)
			{
				if(NewImpact.ResponseComponent == nullptr)
					return;
				
				FCopsGunBulletImpactParams BulletImpactParams;
				BulletImpactParams.ImpactLocation = NewImpact.ResponseComponent.Owner.GetActorTransform().TransformPosition(NewImpact.RelativeImpactLocation);
				NewImpact.ResponseComponent.ApplyBulletImpact(Player, BulletImpactParams);		
			}	
			Manager.PendingBulletImpactsResponse.Reset();	
		}

		if(Manager.TimeLeftUntilReturn >= 0)
		{
			Manager.TimeLeftUntilReturn -= DeltaTime;
			Manager.TimeLeftUntilReturn = Math::Max(Manager.TimeLeftUntilReturn, 0);
		}

		#if !RELEASE
		if (DebugDrawer.IsVisible())
		{
			DrawDebug();
		}
		#endif	
	}

	UFUNCTION(CrumbFunction)
	void CrumbReplicateImpacts(TArray<FScifiCopsGunReplicatedImpactResponseData> Impacts)
	{
		Manager.PendingBulletImpactsResponse.Append(Impacts);
	}

	#if !RELEASE
	void DrawDebug()
	{
		if(Manager.CurrentThrowTargetPoint != nullptr)
		{
			if(Manager.CurrentThrowTargetPoint.IsA(UScifiCopsGunInternalEnvironmentThrowTargetableComponent))
			{
				Debug::DrawDebugDiamond(Manager.CurrentThrowTargetPoint.GetWorldLocation(), 50, LineColor = FLinearColor::LucBlue);
			}
			else
			{
				Debug::DrawDebugDiamond(Manager.CurrentThrowTargetPoint.GetWorldLocation(), 50, LineColor = FLinearColor::Yellow);
			}
		}

		for(auto Weapon : Manager.Weapons)
		{
			if(Weapon.CurrentShootAtTarget != nullptr)
				Debug::DrawDebugDiamond(Weapon.CurrentShootAtTarget.GetWorldLocation(), 40, LineColor = FLinearColor::Red);
		}

		auto Handle = DebugDrawer.Begin();
		GetDebugInfo(Handle, LeftWeapon);
		GetDebugInfo(Handle, RightWeapon);

		if(Manager.CurrentThrowTargetPoint != nullptr)
		{
			if(Manager.CurrentThrowTargetPoint.IsA(UScifiCopsGunInternalEnvironmentThrowTargetableComponent))
			{
				Handle.Text(f"Invironment Target: {Manager.CurrentThrowTargetPoint} ({Manager.CurrentThrowTargetPoint.Owner})");
			}
			else
			{
				Handle.Text(f"Throwable Target: {Manager.CurrentThrowTargetPoint} ({Manager.CurrentThrowTargetPoint.Owner})");
			}
		}
		if(LeftWeapon.CurrentShootAtTarget!=nullptr)
		{
			Handle.Text(f"Left Target: {LeftWeapon.CurrentShootAtTarget.Owner}");
		}
		if(RightWeapon.CurrentShootAtTarget!=nullptr)
		{
			Handle.Text(f"Right Target: {RightWeapon.CurrentShootAtTarget.Owner}");
		}

		if(Manager.WeaponsAreAttachedToPlayer() || Manager.WeaponsAreAttachedToTarget())
		{
			Debug::DrawDebugDirectionArrow(Manager.GetWeaponsMedianLocation(), Manager.GetWeaponsAimDirection(), 300, 25, FLinearColor::Blue);				
			//Debug::DrawDebugDirectionArrow(Manager.InternalEnvironmentTarget.WorldLocation, Manager.InternalEnvironmentTarget.WorldRotation.ForwardVector, 400);

			TArray<UTargetableComponent> Targetables;	
			{
				TArray<UTargetableComponent> Temp;
				TargetContainer.GetRegisteredTargetables(UScifiCopsGunShootTargetableComponent, Temp);
				Targetables.Append(Temp);
			}
			
			for(auto Target : Targetables)
			{
				FVector WeaponsLocation = Manager.GetWeaponsMedianLocation();
				FVector WeaponAimDir = Manager.GetWeaponsAimDirection();
		
				FVector DirToTarget = (Target.WorldLocation - WeaponsLocation).GetSafeNormal();
				float DistanceToTarget = Target.WorldLocation.Distance(WeaponsLocation);
				float AngleToTarget = Math::DotToDegrees(DirToTarget.DotProduct(WeaponAimDir));

				FString DebugText = f"{Target.Owner.GetName()}\nDistance: {DistanceToTarget}\nAngle: {AngleToTarget}";
				Debug::DrawDebugString(Target.WorldLocation, DebugText, FLinearColor::LucBlue);

				if(Target == LeftWeapon.CurrentShootAtTarget)
				{
					Debug::DrawDebugDiamond(Target.WorldLocation, 100);
				}

				if(Target == RightWeapon.CurrentShootAtTarget)
				{
					Debug::DrawDebugDiamond(Target.WorldLocation, 100);
				}
			}
		}
	}

	void GetDebugInfo(FHazeImmediateSectionHandle Handle, AScifiCopsGun Weapon)
	{
	
		Handle.Text(f"Weapon: {Weapon}");
		//Handle.Text(f"CurrentShotBullets: {Weapon.CurrentShotBullets}");
		//Handle.Text(f"BulletsLeftToReload: {Weapon.BulletsLeftToReload}");
		//Handle.Text(f"Player Shoot Input: {Weapon.bPlayerWantsToShoot}");
		Handle.Text(f"IsShooting: {Weapon.bIsShooting}");
		// Handle.Text(f"IsReloading: {Weapon.bIsReloading}");
		
		// if(Weapon.bIsReloading)
		// {
		// 	Handle.Text(f"Time To reload finish: {Weapon.ReloadTimeLeft}");
		// }

		if(!Weapon.IsWeaponAttachedToPlayer())
		{
			Handle.Text(f"MovementSpeed: {Weapon.CurrentMovementSpeed}");
			Handle.Text(f"MovementTurnRate: {Weapon.CurrentTurnSpeed}");
			Handle.Text(f"HasReachedTarget: {Weapon.bHasReachedMoveToTarget}");
		}

		if(Weapon.CurrentShootAtTarget != nullptr)
		{
			FVector DirToTarget = (Weapon.CurrentShootAtTarget.WorldLocation - Weapon.ActorLocation).GetSafeNormal();
			Handle.Text(f"Shootable Target: {Weapon.CurrentShootAtTarget}");
			Handle.Text(f"Shootable Target Distance: {Weapon.CurrentShootAtTarget.WorldLocation.Distance(Weapon.ActorLocation)}");
			Handle.Text(f"Shootable Target Angle: {Math::DotToDegrees(Manager.GetWeaponsAimDirection().DotProduct(DirToTarget))}");

			Debug::DrawDebugArrow(Weapon.MuzzlePoint.WorldLocation, Weapon.CurrentShootAtTarget.WorldLocation, 25, FLinearColor::Red);
		}
		
		Handle.Text("");
	}
	#endif



};