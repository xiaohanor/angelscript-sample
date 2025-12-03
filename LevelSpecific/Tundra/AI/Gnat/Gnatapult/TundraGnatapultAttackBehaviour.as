class UTundraGnatapultAttackBehaviour : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Weapon);
	default Requirements.Add(EBasicBehaviourRequirement::Focus);

	UTundraGnatapultProjectileLauncherComponent Launcher;
	UTundraGnatComponent GnatComp;
	UGentlemanCostComponent GentCostComp;
	UAnimInstanceAIBase AnimInstance;

	UTundraGnatapultSettings Settings;
	float Duration;
	float LaunchTime;

	AHazePlayerCharacter TargetPlayer;
	FVector LocalTargetLocation;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Launcher = UTundraGnatapultProjectileLauncherComponent::Get(Owner);
		GentCostComp = UGentlemanCostComponent::GetOrCreate(Owner);
		GnatComp = UTundraGnatComponent::Get(Owner);
		Settings = UTundraGnatapultSettings::GetSettings(Owner);
		AnimInstance = Cast<UAnimInstanceAIBase>(Cast<AHazeCharacter>(Owner).Mesh.AnimInstance);
		TargetPlayer = Game::Mio;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!Launcher.bLoaded)
			return false;
		if (Launcher.Projectile == nullptr)
			return false;
		if (!TargetComp.IsValidTarget(TargetPlayer))
			return false;
		if(!GentCostComp.IsTokenAvailable(Settings.AttackGentlemanCost))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > Duration)
			return true;
		return false;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		GentCostComp.ClaimToken(this, Settings.AttackGentlemanCost);

		AnimComp.RequestFeature(TundraGnatTags::GnatapultLaunch, EBasicBehaviourPriority::Medium, this);
		UAnimSequence LaunchAnim = AnimInstance.GetRequestedAnimation(TundraGnatTags::GnatapultLaunch, NAME_None);
		Duration = LaunchAnim.PlayLength;
		LaunchTime = LaunchAnim.GetAnimNotifyStateStartTime(UBasicAIActionAnimNotify);

		// Shoot at target, but try to avoid hitting other player
		FVector TargetLoc = TargetPlayer.ActorLocation;
		FVector OtherLoc = TargetPlayer.OtherPlayer.ActorLocation;
		if (TargetLoc.IsWithinDist(OtherLoc, Settings.ProjectileBlastRadius))
			TargetLoc = OtherLoc + (TargetLoc - OtherLoc).GetSafeNormal2D() * Settings.ProjectileBlastRadius;
		LocalTargetLocation = GnatComp.HostBody.WorldTransform.InverseTransformPosition(TargetLoc);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Launcher.bLoaded = false;
		Launcher.Projectile = nullptr;
		GentCostComp.ReleaseToken(this, Settings.AttackGlobalCooldown);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((ActiveDuration > LaunchTime) && TargetPlayer.HasControl())
			CrumbLaunch(LocalTargetLocation);			
		
		if (TargetComp.IsValidTarget(TargetPlayer))
			DestinationComp.RotateTowards(TargetPlayer);
		else 
			DestinationComp.RotateInDirection(Owner.ActorForwardVector);
	}

	UFUNCTION(CrumbFunction)
	void CrumbLaunch(FVector TargetLoc)
	{
		Launcher.Projectile.Launch(TargetLoc, GnatComp.HostBody, TargetPlayer);
		LaunchTime = BIG_NUMBER;
	}
}
