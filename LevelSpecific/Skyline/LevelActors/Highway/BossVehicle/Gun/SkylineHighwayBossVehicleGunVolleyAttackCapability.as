class USkylineHighwayBossVehicleGunVolleyAttackCapability : UHazeCapability
{
	ASkylineHighwayBossVehicle Vehicle;
	UBasicAIHealthComponent HealthComp;
	USkylineHighwayBossVehicleGunComponent GunComp;
	UBasicAIProjectileLauncherComponent LaucherComp;

	USkylineBossVehicleSettings Settings;

	float FiredTime = 0.0;
	int FiredProjectiles = 0;
	bool bIsLeftNext = false;
	TArray<FSkylineHighwayBossVehicleGunVolleyAttackBehaviourProjectileData> Projectiles;
	float CooldownTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{		
		Vehicle = Cast<ASkylineHighwayBossVehicle>(Owner);

		HealthComp = UBasicAIHealthComponent::Get(Owner);
		GunComp = USkylineHighwayBossVehicleGunComponent::GetOrCreate(Owner);
		LaucherComp = UBasicAIProjectileLauncherComponent::GetOrCreate(Owner);

		Settings = USkylineBossVehicleSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Vehicle.TargetPlayer != nullptr && !Vehicle.TargetPlayer.IsPlayerDead())
			return;
		
		if(Vehicle.TargetPlayer != nullptr)
		{
			Vehicle.TargetPlayer = Vehicle.TargetPlayer.OtherPlayer;
			return;
		}

		Vehicle.TargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(GunComp.bInUse)
			return false;
		if (Time::GameTimeSeconds < CooldownTime)
			return false;
		if (Vehicle.TargetPlayer.IsPlayerDead())
			return false;
		if (!Owner.ActorCenterLocation.IsWithinDist(Vehicle.TargetPlayer.ActorCenterLocation, Settings.VolleyMaxAttackRange))
			return false;
		if (Owner.ActorCenterLocation.IsWithinDist(Vehicle.TargetPlayer.ActorCenterLocation, Settings.VolleyMinAttackRange))
			return false;
		if (Owner.IsCapabilityTagBlocked(n"Attack"))
			return false;
		if (Owner.IsCapabilityTagBlocked(n"Volley"))
			return false;
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Arena)
			return true;
		if(Vehicle.CurrentMode == ESkylineHighwayBossVehicleMode::Move)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(CooldownTime > 0)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		GunComp.bInUse = true;
		FiredProjectiles = 0;
		CooldownTime = 0;
		
		Projectiles.Empty();
		for(int i = 0; i < Settings.VolleyProjectileAmount; i++)
		{
			FVector TargetLoc = Vehicle.TargetPlayer.ActorLocation;
			FHazeTraceSettings Trace = Trace::InitChannel(ECollisionChannel::WorldGeometry);
			Trace.UseLine();
			FHitResult Hit = Trace.QueryTraceSingle(TargetLoc, TargetLoc - FVector::UpVector * 500);
			if(Hit.bBlockingHit)
				TargetLoc = Hit.Location;

			float Angle = Math::IntegerDivisionTrunc(360, Settings.VolleyProjectileAmount-1) * i;
			if(i > 0)
				TargetLoc += Owner.ActorForwardVector.RotateAngleAxis(Angle, Owner.ActorUpVector) * Math::RandRange(75, 150);

			FHitResult OffsetHit = Trace.QueryTraceSingle(TargetLoc, TargetLoc - FVector::UpVector * 500);
			if(OffsetHit.bBlockingHit)
				TargetLoc = OffsetHit.Location;

			FSkylineHighwayBossVehicleGunVolleyAttackBehaviourProjectileData Data;
			Data.TargetLocation = TargetLoc;

			Data.Weapon = LaucherComp;
			Data.Left = bIsLeftNext;
			bIsLeftNext = !bIsLeftNext;

			Data.Projectile = Data.Weapon.SpawnProjectile();
			Data.Projectile.Launcher = Data.Weapon.Wielder;
			Data.Projectile.LaunchingWeapon = this;	
			Data.Projectile.Prime();
			Data.Projectile.Owner.AttachRootComponentTo(Data.Weapon, NAME_None, EAttachLocation::KeepWorldPosition);
			Data.Weapon.OnPrimeProjectile.Broadcast(Data.Projectile);
			Data.Projectile.HazeOwner.AddActorVisualsBlock(this);

			if(OffsetHit.bBlockingHit)
			{
				FSkylineHighwayBossVehicleGunProjectileEffectHandlerOnTelegraphData TelegraphData;
				TelegraphData.TargetLocation = TargetLoc;
				USkylineHighwayBossVehicleGunProjectileEffectHandler::Trigger_OnTelegraph(Data.Projectile.HazeOwner, TelegraphData);
			}

			Projectiles.Add(Data);
		}	

		USkylineHighwayBossVehicleEffectHandler::Trigger_OnGunStartTelegraphing(Owner, FSkylineHighwayBossVehicleEffectHandlerOnGunStartTelegraphingData(Vehicle.GunLaunchPointLeft, Vehicle.GunLaunchPointRight, Settings.VolleyTelegraphDuration));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		bHasStoppedTelegraphing = false;
		Vehicle.TargetPlayer = Vehicle.TargetPlayer.OtherPlayer;
		GunComp.CancelAim(this);
		GunComp.bInUse = false;

		for(FSkylineHighwayBossVehicleGunVolleyAttackBehaviourProjectileData Projectile : Projectiles)
		{
			if(!Projectile.Projectile.bIsLaunched)
				Projectile.Projectile.Expire();
		}
	}

	bool bHasStoppedTelegraphing = false;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float FinalGravity = GetFinalGravity(Projectiles[0].Weapon.LaunchLocation, Projectiles[0].TargetLocation);
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(Projectiles[0].Weapon.LaunchLocation, Projectiles[0].TargetLocation, FinalGravity, Settings.VolleyLaunchHeight);
		GunComp.SetAim(LaunchVelocity.Rotation(), Settings.VolleyTelegraphDuration, this);

		if(ActiveDuration < Settings.VolleyTelegraphDuration)
		{
			return;
		}
		if (!bHasStoppedTelegraphing)
		{
			bHasStoppedTelegraphing = true;
			USkylineHighwayBossVehicleEffectHandler::Trigger_OnGunStopTelegraphing(Owner);
		}


		// Fire and draft version of kickback
		if(FiredProjectiles < Settings.VolleyProjectileAmount && (FiredTime == 0 || Time::GetGameTimeSince(FiredTime) > Settings.VolleyProjectileInterval))
		{
			FireProjectile(Projectiles[FiredProjectiles]);
		}
		
		// Let barrel rotation get to rest before deactivating
		if(FiredProjectiles >= Settings.VolleyProjectileAmount)
		{
			CooldownTime = Time::GameTimeSeconds + Settings.VolleyAttackCooldown;
		}
	}
	
	UFUNCTION(NotBlueprintCallable)
	private void FireProjectile(FSkylineHighwayBossVehicleGunVolleyAttackBehaviourProjectileData Data)
	{
		UBasicAIProjectileComponent Projectile = Data.Projectile;
		
		Projectile.Launcher = Data.Weapon.Wielder;
		Projectile.LaunchingWeapon = this;	
		Projectile.Owner.DetachRootComponentFromParent(true);
		Data.Weapon.LastLaunchedProjectile = Projectile;
		Data.Weapon.OnLaunchProjectile.Broadcast(Projectile);

		USceneComponent LaunchPoint = Vehicle.GunLaunchPointRight;
		if (Data.Left)
			LaunchPoint = Vehicle.GunLaunchPointLeft;

		float FinalGravity = GetFinalGravity(Data.Weapon.LaunchLocation, Data.TargetLocation);
		FVector LaunchVelocity = Trajectory::CalculateVelocityForPathWithHeight(LaunchPoint.WorldLocation, Data.TargetLocation, FinalGravity, 500);

		Projectile.Launch(LaunchVelocity);	
		Projectile.Gravity = FinalGravity;
		Projectile.HazeOwner.RemoveActorVisualsBlock(this);
		Projectile.TargetedLocation = Data.TargetLocation;
		Projectile.Owner.ActorLocation = LaunchPoint.WorldLocation;
		Cast<ASkylineHighwayBossVehicleGunProjectile>(Projectile.Owner).CheckHeight = true;
		Cast<ASkylineHighwayBossVehicleGunProjectile>(Projectile.Owner).LaunchLocation = Data.Weapon.LaunchLocation;

		FiredProjectiles++;
		FiredTime = Time::GetGameTimeSeconds();

		USkylineHighwayBossVehicleEffectHandler::Trigger_OnGunFire(Owner, FSkylineHighwayBossVehicleEffectHandlerOnGunFireData(LaunchPoint, FiredProjectiles));
	}

	float GetFinalGravity(FVector LaunchLocation, FVector TargetLocation)
	{
		float Distance = LaunchLocation.Distance(TargetLocation);
		float DistAlpha = Math::Clamp(1 - (Distance / 12000), 0.25, 2);
		float FinalGravity = Settings.VolleyLaunchGravity * DistAlpha * DistAlpha;
		return FinalGravity;
	}
}

struct FSkylineHighwayBossVehicleGunVolleyAttackBehaviourProjectileData
{
	UBasicAIProjectileLauncherComponent Weapon;
	UBasicAIProjectileComponent Projectile;
	FVector TargetLocation;
	bool Left;
}

