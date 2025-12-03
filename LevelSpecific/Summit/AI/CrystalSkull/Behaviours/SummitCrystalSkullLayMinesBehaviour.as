class USummitCrystalSkullLayMinesBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	USummitCrystalSkullSettings FlyerSettings;

	UGentlemanCostComponent GentCostComp;
	UBasicAIHealthComponent HealthComp;
	USummitCrystalSkullComponent FlyerComp;
	UBasicAIProjectileLauncherComponent MineLauncher;

	FVector Destination;
	float LaunchMineTime;
	int NumLaunched;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		FlyerSettings = USummitCrystalSkullSettings::GetSettings(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		HealthComp = UBasicAIHealthComponent::GetOrCreate(Owner); 
		FlyerComp = USummitCrystalSkullComponent::GetOrCreate(Owner);
		MineLauncher = UBasicAIProjectileLauncherComponent::Get(Owner);
	}

	bool WantsToLayMines() const
	{
		if (!Cooldown.IsOver())
			return false; 
		if (!Requirements.CanClaim(BehaviourComp, this))
			return false;
		if (!TargetComp.HasValidTarget())
			return false;

		// Always evade at least once between each attack
		if (FlyerComp.LastAttackTime > FlyerComp.LastEvadeTime - 0.1)
			return false;		

		AHazeActor Target = TargetComp.Target;
		FVector TargetLoc = TargetComp.Target.ActorLocation;
		if (!Owner.ActorLocation.IsWithinDist(TargetLoc, FlyerSettings.LayMinesMaxRange))
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetLoc, FlyerSettings.LayMinesMinRange))
			return false;

		float MinCosAngle = Math::Cos(Math::DegreesToRadians(FlyerSettings.LayMinesMinAngle));
		if (Target.ActorForwardVector.DotProduct((Owner.ActorLocation - TargetLoc).GetSafeNormal()) < MinCosAngle)
			return false;	
	
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if(!WantsToLayMines())
			return false;
		// Note that we skip queue
		if(!GentCostComp.IsTokenAvailable(FlyerSettings.LayMinesGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > GetFullDuration())
			return true;

		return false;
	}

	float GetFullDuration() const
	{
		return FlyerSettings.LayMinesTelegraphDuration + FlyerSettings.LayMinesDuration + FlyerSettings.LayMinesRecoverDuration;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, FlyerSettings.LayMinesGentlemanCost);
		Destination = Owner.ActorLocation + (Owner.ActorLocation - TargetComp.Target.ActorLocation).GetSafeNormal() * FlyerSettings.LayMinesMoveSpeed * GetFullDuration();
		LaunchMineTime = Time::GameTimeSeconds + FlyerSettings.LayMinesTelegraphDuration;
		NumLaunched = 0;
		USummitCrystalSkullEventHandler::Trigger_OnTelegraphMineLaying(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(FlyerSettings.LayMinesCooldown);
		GentCostComp.ReleaseToken(this, FlyerSettings.LayMinesTokenCooldown);
		FlyerComp.ClearVulnerable();
		FlyerComp.LastAttackTime = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Move to destination, dropping mines as we go
		if (Owner.ActorLocation.IsWithinDist(Destination, FlyerSettings.LayMinesMoveSpeed * 0.1))
			Destination = Owner.ActorLocation + (Owner.ActorLocation - TargetComp.Target.ActorLocation).GetSafeNormal() * FlyerSettings.LayMinesMoveSpeed;
		DestinationComp.MoveTowards(Destination, FlyerSettings.LayMinesMoveSpeed);

		if (HasControl() && (NumLaunched < FlyerSettings.LayMinesNumber) && (Time::GameTimeSeconds > LaunchMineTime))
		{
			FRotator LaunchRot = (TargetComp.Target.ActorLocation - MineLauncher.LaunchLocation).Rotation();
			LaunchRot.Yaw += Math::RandRange(-1.0, 1.0) * FlyerSettings.LayMinesScatterYaw;
			LaunchRot.Pitch += Math::RandRange(-1.0, 1.0) * FlyerSettings.LayMinesScatterPitch;
			CrumbLaunchMine(LaunchRot.Vector() * FlyerSettings.MinesMoveSpeed);
			LaunchMineTime += (FlyerSettings.LayMinesDuration / float(FlyerSettings.LayMinesNumber));
			NumLaunched++;
		}

		if (ActiveDuration > FlyerSettings.LayMinesTelegraphDuration + FlyerSettings.LayMinesDuration)
		{
			// Show that we're not able to dodge after mines have been deployed, then resume signs of being alert just before actually becoming able to dodge
			if (ActiveDuration < GetFullDuration() - 0.5)
				FlyerComp.SetVulnerable();
			else
				FlyerComp.ClearVulnerable();
		}

#if EDITOR
	 	// Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
		{
			Debug::DrawDebugSphere(Destination, 5000, 12, FLinearColor::Purple, 100);					
			Debug::DrawDebugSphere(TargetComp.Target.ActorCenterLocation + FVector(0,0,400), 100, 4, FLinearColor::Purple, 10);
		}
#endif
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunchMine(FVector LaunchVelocity)
	{
		USummitCrystalSkullEventHandler::Trigger_OnLayMine(Owner);
		MineLauncher.Launch(LaunchVelocity);
	}
}

