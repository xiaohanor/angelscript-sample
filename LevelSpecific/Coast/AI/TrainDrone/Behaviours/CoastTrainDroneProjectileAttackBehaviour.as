class UCoastTrainDroneProjectileAttackBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus); 

	float TelegraphEndTime;
	AHazePlayerCharacter PlayerTarget;

	UGentlemanCostComponent GentCostComp;
	UGentlemanCostQueueComponent GentCostQueueComp;
	UBasicAIHealthComponent HealthComp;
	UCoastTrainDroneSettings DroneSettings;
	UBasicAIProjectileLauncherComponent Weapon;
	float ShootTime = 0.0;
	
	int TypeCycle;

	// FHazeAcceleratedFloat SpinSpeed; 
	
	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GentCostQueueComp = UGentlemanCostQueueComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::Get(Owner);
		DroneSettings = UCoastTrainDroneSettings::GetSettings(Owner);
		Weapon = UBasicAIProjectileLauncherComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive() && HealthComp.IsAlive() && !IsBlocked() && WantsToAttack())
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
		if (!Owner.ActorCenterLocation.IsWithinDist(TargetComp.Target.ActorCenterLocation, DroneSettings.ProjectileAttackRange))
			return false;

		// Only attack when we're facing target
		FVector ToTarget = (TargetComp.Target.ActorCenterLocation - Owner.ActorCenterLocation);
		ToTarget.Z = 0.0;
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal()) < 0.707) 
			return false;

		// Only start attack against players when in front and in camera direction
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(TargetComp.Target);
		if (Player != nullptr)
		{
			FVector ViewYawDir = FRotator(0.0, Player.ViewRotation.Yaw, 0.0).Vector();
			if (ViewYawDir.DotProduct(-ToTarget) < 0.707)
				return false;
		}
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!GentCostQueueComp.IsNext(this))
			return false;
		if(!GentCostComp.IsTokenAvailable(DroneSettings.ProjectileAttackGentlemanCost))
			return false;		
		if (!WantsToAttack())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (!TargetComp.HasValidTarget())
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, DroneSettings.ProjectileAttackGentlemanCost);

		// Telegraph for a while, then let loose!
		AnimComp.RequestFeature(LocomotionFeatureAITags::Taunt, SubTagAITaunts::Telegraph, EBasicBehaviourPriority::Medium, this);
		// SpinSpeed.SnapTo(0.0);

		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(Weapon, DroneSettings.ProjectileAttackTelegraphDuration));		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		GentCostComp.ReleaseToken(this, DroneSettings.ProjectileAttackTokenCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		DestinationComp.RotateTowards(TargetComp.Target);
		
		if (ActiveDuration > DroneSettings.ProjectileAttackTelegraphDuration)
		{
			if(HasControl())
				CrumbShoot();
			Cooldown.Set(DroneSettings.ProjectileAttackCooldownTime);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbShoot()
	{
		FVector LaunchVelocity = (TargetComp.Target.FocusLocation - Weapon.LaunchLocation).GetSafeNormal() * DroneSettings.ProjectileLaunchSpeed;
		UBasicAIProjectileComponent Projectile = Weapon.Launch(LaunchVelocity, LaunchVelocity.Rotation());

		ACoastTrainDroneProjectile ProjectileActor = Cast<ACoastTrainDroneProjectile>(Projectile.Owner);

		if(TypeCycle == 0)
			ProjectileActor.Type = ECoastTrainDroneProjectileType::Disc;
		if(TypeCycle == 1)
			ProjectileActor.Type = ECoastTrainDroneProjectileType::Propeller;
		if(TypeCycle == 2)
			ProjectileActor.Type = ECoastTrainDroneProjectileType::Pump;

		if(TypeCycle == 2)
			TypeCycle = 0;
		else
			TypeCycle++;

		// If the drone has been spawned as attached to an train cart, attach the projectile to it
		UHazeActorRespawnableComponent RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		if (RespawnComp != nullptr && RespawnComp.Spawner != nullptr && RespawnComp.Spawner.AttachParentActor != nullptr)
			Projectile.Owner.AttachToActor(RespawnComp.Spawner.AttachParentActor, AttachmentRule = EAttachmentRule::KeepWorld);

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Weapon, 1, 1));
	}
}

