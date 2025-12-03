struct FSkylineAttackShipProjectileLaunchParam
{
	AHazeActor Target;
}

class USkylineAttackShipProjectileLaunchCapability : UHazeChildCapability
{
	default CapabilityTags.Add(n"SkylineAttackShipAttack");

	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::OnlyCrumbNetwork;

	ASkylineAttackShip AttackShip;

	TArray<USkylineAttackShipProjectileLauncherComponent> ProjectileLaunchers;

	float NextLaunchTime = 0.0;
	int LaunchIndex = 0;
	float LaunchInterval = 0.1;

	float InitialDelay = 3.0;
	float PreLaunchDelay = 3.0;

	AHazeActor Target;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackShip = Cast<ASkylineAttackShip>(Owner);
		AttackShip.GetComponentsByClass(ProjectileLaunchers);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSkylineAttackShipProjectileLaunchParam& Params) const
	{
		if (!AttackShip.bAttackReady)
			return false;

		if (!IsFreeToAttack())
			return false;

		if (DeactiveDuration < 5.0)	
			return false;

		if (AttackShip.AttackTarget.Get() == nullptr)
			return false;

		Params.Target = AttackShip.AttackTarget.Get();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
//		if (LaunchIndex >= ProjectileLaunchers.Num())
//			return true;

		if (ActiveDuration > 5.5)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSkylineAttackShipProjectileLaunchParam Params)
	{
		for (auto ProjectileLauncher : ProjectileLaunchers)
			ProjectileLauncher.Initialize();

		LaunchIndex = 0;
		NextLaunchTime = Time::GameTimeSeconds + PreLaunchDelay;

		Target = Params.Target;

		PrintToScreen("Fire Missiles at: " + Target, 3.0, FLinearColor::Green);

		USkylineAttackShipEventHandler::Trigger_OnStartAimLaser(AttackShip, FSkylineAttackShipAttackEventData(Cast<AHazePlayerCharacter>(Target), nullptr));
		UBasicAIWeaponEventHandler::Trigger_OnTelegraphShooting(Owner, FWeaponHandlingTelegraphParams(PreLaunchDelay));		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
//		InitialDelay -= DeltaTime;
//		if (InitialDelay > 0.0)
//			return;

		if (Time::GameTimeSeconds < NextLaunchTime)
		{
			AttackShip.LaserPointer.SetHiddenInGame(false);
			FVector ToTarget = Target.ActorCenterLocation - AttackShip.LaserPointer.WorldLocation;
			float DistanceToTarget = ToTarget.Size();

			AttackShip.LaserPointer.SetWorldRotation(FQuat::MakeFromZ(ToTarget.SafeNormal));
			AttackShip.LaserPointer.SetWorldScale3D(FVector(AttackShip.LaserPointer.WorldScale.X, AttackShip.LaserPointer.WorldScale.Y, DistanceToTarget * 0.01));

//			Debug::DrawDebugLine(AttackShip.LaserPointer.WorldLocation, Target.ActorCenterLocation, FLinearColor::Red, 4.0, 0.0);
		}
		else
		{
			AttackShip.LaserPointer.SetHiddenInGame(true);
		}

		if (HasControl())
		{
			while (Time::GameTimeSeconds >= NextLaunchTime && LaunchIndex < ProjectileLaunchers.Num())
			{
				auto Projectile = ProjectileLaunchers[LaunchIndex].SpawnProjectile();
				CrumbLaunchProjectile(LaunchIndex, Projectile, Target);

				NextLaunchTime += LaunchInterval;
				LaunchIndex++;
			}
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchProjectile(int ProjectileLaunchIndex, ASkylineAttackShipProjectileBase Projectile, AActor PlayerTarget)
	{
		ProjectileLaunchers[ProjectileLaunchIndex].LaunchProjectile(Projectile, PlayerTarget);

		UBasicAIWeaponEventHandler::Trigger_OnShotFired(Owner, FWeaponHandlingLaunchParams(Projectile.ActorLocation, Projectile.Velocity, LaunchIndex, ProjectileLaunchers.Num()));
		USkylineAttackShipEventHandler::Trigger_OnFireMissiles(AttackShip, FSkylineAttackShipAttackEventData(Cast<AHazePlayerCharacter>(PlayerTarget), Projectile));
	}

	bool IsFreeToAttack() const
	{
		

		auto Team = HazeTeam::GetTeam(n"SkylineAttackShips");

		if(Team==nullptr)
			return false;

		for (auto Member : Team.GetMembers())
		{
			if (Member == nullptr)
				continue;

			if(Team.GetMembers().IsEmpty())
				return false;				

			auto AsAttackShip = Cast<ASkylineAttackShip>(Member);
			if (!IsValid(AsAttackShip.Shield))
				return false;

			if (AsAttackShip.Shield.bIsBroken)
				return false;

			if (AsAttackShip.IsAnyCapabilityActive(n"SkylineAttackShipAttack"))
				return false;
		}
	
		return true;
	}
}