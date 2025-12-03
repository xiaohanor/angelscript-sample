
class UScifiPlayerGravityGrenadeManagerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"GravityGrenade");
	default CapabilityTags.Add(n"GravityGrenadeManager");

	default DebugCategory = n"GravityGrenade";
	
	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 110;

	UScifiPlayerGravityGrenadeManagerComponent Manager;
	UPlayerTargetablesComponent TargetContainer;
	AScifiPlayerGravityGrenadeWeapon Weapon;
	UScifiPlayerGravityGrenadeSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Manager = UScifiPlayerGravityGrenadeManagerComponent::Get(Player);
		Settings = Manager.Settings;
		TargetContainer = UPlayerTargetablesComponent::Get(Player);
		//Manager.EnsureWeaponSpawn(Player, LeftWeapon, RightWeapon);
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
					FScifiPlayerGravityGrenadeWeaponImpact Impact;

					Impact.bIsValid = Projectile.MovementImpact.bIsValid;
					Impact.ImpactLocation = Projectile.MovementImpact.ImpactLocation;
					Impact.Actor = Projectile.MovementImpact.Actor;
					Impact.Target = Projectile.MovementImpact.Target;

					//FScifiPlayerShieldBusterWeaponImpact ShieldBusterImpact = Projectile.MovementImpact;
					FScifiPlayerGravityGrenadeWeaponImpact GravityGrenadeImpact = Projectile.MovementImpact;

					// Handle the different impacts in accending order
					if(!HandleGravityObjectImpacts(Impact))
					{
						HandleGenericImpacts(Impact);
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
			Manager.CurrentTarget = TargetContainer.GetPrimaryTarget(UScifiGravityGrenadeTargetableComponent);

			// TEMP
			if(Manager.CurrentTarget != nullptr)
			{
				Debug::DrawDebugDiamond(Manager.CurrentTarget.GetWorldLocation(), 50, LineColor = FLinearColor::LucBlue);
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

	bool HandleGenericImpacts(FScifiPlayerGravityGrenadeWeaponImpact Impact)
	{
		if(Impact.Actor == nullptr)
			return false;

		auto Target = Cast<UScifiGravityGrenadeTargetableComponent>(Impact.Target);
		if(Target != nullptr)
		{
			Manager.CrumbAddGenericTargetImpact(Impact);
		}

		return true;
	}

	bool HandleGravityObjectImpacts(FScifiPlayerGravityGrenadeWeaponImpact Impact)
	{
		auto Wall = Cast<AScifiGravityGrenadeObject>(Impact.Actor);
		if(Wall == nullptr)
			return false;

		FScifiGravityGrenadePendingGravityObjectImpactData NewImpact;
		NewImpact.Impact = Impact;

		auto Target = Cast<UScifiGravityGrenadeTargetableComponent>(Impact.Target);
		if(Target != nullptr)
		{
			Manager.CrumbAddGravityObjectImpact(NewImpact);
		}

		return true;
	}

	UFUNCTION(CrumbFunction)
	void CrumbDeactiveRemoteProjectile(AScifiPlayerGravityGrenadeWeaponProjectile Projectile)
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

