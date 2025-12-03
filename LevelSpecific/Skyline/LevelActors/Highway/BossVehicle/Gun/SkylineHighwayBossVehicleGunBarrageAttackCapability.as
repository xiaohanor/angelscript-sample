class USkylineHighwayBossVehicleGunBarrageAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Barrage");

	ASkylineHighwayBossVehicleArenaCenter Center;
	ASkylineHighwayBossVehicle Vehicle;

	UBasicAIHealthComponent HealthComp;
	USkylineHighwayBossVehicleGunComponent GunComp;
	UBasicAIProjectileLauncherComponent LaucherComp;

	USkylineBossVehicleSettings Settings;

	float FiredTime = 0.0;
	int FiredProjectiles = 0;
	bool bIsLeftNext = false;

	bool AttackForwards;
	float AttackRange = 0;
	float AttackRangeMax = 5000;
	float AttackRangeMin = 4000;
	float Gravity = 982 * 5;
	float Height = 1500;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);
		Center = TListedActors<ASkylineHighwayBossVehicleArenaCenter>().Single;

		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GunComp = USkylineHighwayBossVehicleGunComponent::GetOrCreate(Owner);
		LaucherComp = UBasicAIProjectileLauncherComponent::GetOrCreate(Owner);

		Settings = USkylineBossVehicleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (Owner.IsCapabilityTagBlocked(n"Attack"))
			return false;
		if(GunComp.bInUse)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		FiredProjectiles = 0;

		USkylineHighwayBossVehicleEffectHandler::Trigger_OnGunStartTelegraphing(Owner, FSkylineHighwayBossVehicleEffectHandlerOnGunStartTelegraphingData(Vehicle.GunLaunchPointLeft, Vehicle.GunLaunchPointRight, Settings.BarrageTelegraphDuration));

		float BaseDistance = (Center.ActorLocation - Owner.ActorLocation).DotProduct(Owner.ActorForwardVector);
		AttackRangeMin = BaseDistance - 700;
		AttackRangeMax = BaseDistance + 600;
		AttackRange = AttackRangeMax;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bHasStoppedTelegraphing = false;
		GunComp.CancelAim(this);
		GunComp.bInUse = false;
		GunComp.bIsInBarrage = false;
	}

	bool bHasStoppedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector AimLocation = LaucherComp.LaunchLocation + Owner.ActorForwardVector * AttackRange;
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaucherComp.WorldLocation, AimLocation, Gravity, Height);
		GunComp.SetAim(LaunchVelocity.Rotation(), Settings.BarrageTelegraphDuration, this);
		GunComp.bInUse = true;
		GunComp.bIsInBarrage = true;

		if(ActiveDuration < Settings.BarrageTelegraphDuration)
		{
			return;
		}
		if (!bHasStoppedTelegraphing)
		{
			bHasStoppedTelegraphing = true;
			USkylineHighwayBossVehicleEffectHandler::Trigger_OnGunStopTelegraphing(Owner);
		}

		// Fire and draft version of kickback
		if(FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > 0.05)
		{
			USceneComponent LaunchPoint = Vehicle.GunLaunchPointRight;
			if (bIsLeftNext)
				LaunchPoint = Vehicle.GunLaunchPointLeft;

			if(AttackForwards && AttackRange > AttackRangeMax)	
				AttackForwards = false;
			else if(!AttackForwards && AttackRange < AttackRangeMin)
				AttackForwards = true;

			FVector RightVector = Owner.ActorRightVector;
			float RangeOffset = 75;
			AttackRange += AttackForwards ? RangeOffset : -RangeOffset;
			FVector OffsetVector = bIsLeftNext ? RightVector : -RightVector;
			FVector SideOffset = OffsetVector * Math::RandRange(0, Settings.BarrageProjectileSideOffsetMax);
			FVector TargetLoc = LaucherComp.LaunchLocation + Owner.ActorForwardVector * AttackRange + SideOffset;

			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(TargetLoc + FVector::UpVector * -250, TargetLoc + FVector::UpVector * -1250);
			if(Hit.bBlockingHit)
				TargetLoc = Hit.Location;

			FSkylineHighwayBossVehicleGunBarrageAttackProjectileData Data;
			Data.Weapon = LaucherComp;
			Data.TargetLocation = TargetLoc;
			Data.Projectile = Data.Weapon.SpawnProjectile();
			Data.Projectile.Launcher = Data.Weapon.Wielder;
			Data.Projectile.LaunchingWeapon = this;	
			Data.Projectile.Prime();
			Data.Projectile.Owner.AttachRootComponentTo(Data.Weapon, NAME_None, EAttachLocation::KeepWorldPosition);
			Data.Weapon.OnPrimeProjectile.Broadcast(Data.Projectile);
			Data.Projectile.HazeOwner.AddActorVisualsBlock(this);

			if(Hit.bBlockingHit)
			{
				FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnTelegraphData TelegraphData;
				TelegraphData.TargetLocation = TargetLoc;
				USkylineHighwayBossVehicleGunProjectileEffectHandler::Trigger_OnTelegraph(Data.Projectile.HazeOwner, TelegraphData);
			}

			USkylineHighwayBossVehicleEffectHandler::Trigger_OnGunFire(Owner, FSkylineHighwayBossVehicleEffectHandlerOnGunFireData(LaunchPoint, FiredProjectiles));

			FireProjectile(Data);
			bIsLeftNext = !bIsLeftNext;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(FSkylineHighwayBossVehicleGunBarrageAttackProjectileData Data)
	{
		UBasicAIProjectileComponent Projectile = Data.Projectile;
		
		Projectile.Launcher = Data.Weapon.Wielder;
		Projectile.LaunchingWeapon = this;	
		Projectile.Owner.DetachRootComponentFromParent(true);
		Data.Weapon.LastLaunchedProjectile = Projectile;
		Data.Weapon.OnLaunchProjectile.Broadcast(Projectile);


		USceneComponent LaunchPoint = Vehicle.GunLaunchPointRight;
		if (bIsLeftNext)
			LaunchPoint = Vehicle.GunLaunchPointLeft;
		
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchPoint.WorldLocation, Data.TargetLocation, Gravity, Height);
		Projectile.Launch(LaunchVelocity);
		Projectile.Gravity = Gravity;
		Projectile.HazeOwner.RemoveActorVisualsBlock(this);
		Projectile.TargetedLocation = Data.TargetLocation;
		Projectile.Owner.ActorLocation = LaunchPoint.WorldLocation;

		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();
	}
}

struct FSkylineHighwayBossVehicleGunBarrageAttackProjectileData
{
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIProjectileComponent Projectile;
	FVector TargetLocation;
}