
class UScifiPlayerShieldBusterManagerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"ShieldBuster");
	default CapabilityTags.Add(n"ShieldBusterManager");

	default DebugCategory = n"ShieldBuster";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	UScifiPlayerShieldBusterManagerComponent Manager;
	UPlayerTargetablesComponent TargetContainer;
	AScifiPlayerShieldBusterWeapon LeftWeapon;
	AScifiPlayerShieldBusterWeapon RightWeapon;
	UScifiPlayerShieldBusterSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerShieldBusterManagerComponent::Get(Player);
		Settings = Manager.Settings;
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
		Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
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

	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Manager.CurrentTarget = nullptr;
		Manager.DeactivateAllProjectiles();
		Manager.PendingWallImpacts.Reset();
		Manager.PendingFieldImpacts.Reset();
		Manager.PendingTargetGenericImpacts.Reset();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		auto ActiveProjectiles = Manager.ActiveProjectiles;

		if(HasControl())
		{
			for(int i = Manager.ActiveProjectiles.Num() - 1; i >= 0; --i)
			{
				auto Projectile = Manager.ActiveProjectiles[i];

				// Update the movement on all the projetiles
				Projectile.MoveControl(DeltaTime);

				// We sort all the imapcts here so we can handle them in individual capabilities network safe
				if(Projectile.HasImpact())
				{	
					FScifiPlayerShieldBusterWeaponImpact Impact = Projectile.MovementImpact;

					// Handle the different impacts in accending order
					if(!HandleImpactAgainstShieldWall(Impact))
					{
						if(!HandleImpactAgainstShieldFields(Impact))
						{
							HandleGenericImpacts(Impact);
						}
					}

					// Return the projetile to the pool
					CrumbDeactiveRemoteProjectile(Projectile);
					Manager.DeactiveProjectileAtActiveIndex(i);	
				}
				// So we dont fly away forever
				else if(Time::GetGameTimeSince(Projectile.ActivationTime) > Settings.ProjectileMaxLifeTime)
				{
					CrumbDeactiveRemoteProjectile(Projectile);
					Manager.DeactiveProjectileAtActiveIndex(i);	
				}
			}

			// Update the current target
			Manager.CurrentTarget = TargetContainer.GetPrimaryTarget(UScifiShieldBusterTargetableComponent);

			// TEMP
			if(Manager.CurrentTarget != nullptr)
			{
				Debug::DrawDebugDiamond(Manager.CurrentTarget.GetWorldLocation(), 50, LineColor = FLinearColor::LucBlue);
			}
			
			// Fast reload if we have that setting
			if(Manager.CurrentShotBullets > 0 
			&& Settings.InactiveAutomaticReload >= 0 
			&& !Manager.bIsReloading
			&& Time::GetGameTimeSince(Manager.LastShotGameTime) >= Settings.InactiveAutomaticReload)
			{
				Manager.CurrentShotBullets = 0;
				Manager.bIsReloading = false;
			}
			else if(Manager.bIsReloading && Time::GetGameTimeSeconds() >= Manager.ReloadFinishTime)
			{
				Manager.CurrentShotBullets = 0;
				Manager.bIsReloading = false;
			}
		}
		// Remote update
		else
		{
			for(auto Projectile : ActiveProjectiles)
			{
				// Update the movement on all the projetiles
				Projectile.MoveRemote(DeltaTime);
			}
		}
	}

	bool HandleImpactAgainstShieldWall(FScifiPlayerShieldBusterWeaponImpact Impact)
	{
		auto Wall = Cast<AScifiShieldBusterEnergyWall>(Impact.Actor);
		if(Wall == nullptr)
			return false;

		auto WallTarget = Cast<UScifiShieldBusterEnergyWallTargetableComponent>(Impact.Target);
		if(Wall.CanCut() && WallTarget != nullptr)
		{
			// Make sure we have a valid wallcutter
			FScifiShieldBusterPendingWallImpactData NewImpact;
			if(WallTarget.WallOwner.CurrentWallCutter == nullptr)
				NewImpact.WallCutter = Manager.GetOrCreateControlSideWallCutter();
			else
				NewImpact.WallCutter = WallTarget.WallOwner.CurrentWallCutter;
			NewImpact.Impact = Impact;

			Manager.CrumbAddPendingWallImpact(NewImpact);
		}

		return true;
	}

	bool HandleImpactAgainstShieldFields(FScifiPlayerShieldBusterWeaponImpact Impact)
	{
		auto Field = UScifiShieldBusterField::Get(Impact.Actor);
		if(Field == nullptr)
			return false;

		auto FieldTarget = Cast<UScifiShieldBusterFieldTargetableComponent>(Impact.Target);
		if(Field.CanBreak() && FieldTarget != nullptr)
		{
			FScifiShieldBusterPendingFieldImpactData NewImpact;
			NewImpact.Impact = Impact;
			Manager.CrumbAddPendingFieldImpact(NewImpact);
		}

		return true;
	}

	bool HandleGenericImpacts(FScifiPlayerShieldBusterWeaponImpact Impact)
	{
		if(Impact.Actor == nullptr)
			return false;

		auto Target = Cast<UScifiShieldBusterTargetableComponent>(Impact.Target);
		if(Target != nullptr)
		{
			Manager.CrumbAddGenericTargetImpact(Impact);
		}

		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactiveRemoteProjectile(AScifiPlayerShieldBusterWeaponProjectile Projectile)
	{
		if(!HasControl())
		{
			int Index = Manager.ActiveProjectiles.FindIndex(Projectile);
			if(Index >= 0)
			{
				Manager.DeactiveProjectileAtActiveIndex(Index);
			}	
		}
	}
};

