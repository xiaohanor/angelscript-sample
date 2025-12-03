class UBasicTeleportChaseBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);
	default Requirements.AddBlock(EBasicBehaviourRequirement::Weapon); // No attack when teleporting!

	UBasicAITeleporterSettings TeleporterSettings;
	UPathfollowingSettings PathfollowingSettings;
	UGroundPathfollowingSettings GroundPathfollowingSettings;

	bool bTeleporting = false;
	float TeleportTime;
	float ReappearTime;
	float SettleTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		TeleporterSettings = UBasicAITeleporterSettings::GetSettings(Owner);
		PathfollowingSettings = UPathfollowingSettings::GetSettings(Owner);
		GroundPathfollowingSettings = UGroundPathfollowingSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (Owner.ActorLocation.IsWithinDist(TargetComp.Target.ActorLocation, TeleporterSettings.TeleportChaseMinRange))
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

		// Owner.TriggerEffectEvent(n"TeleportChase.TeleportDisappear"); // UNKNOWN EFFECT EVENT NAMESPACE

		if (TeleporterSettings.TeleportChaseTelegraphDuration > 0.0)
		 	AnimComp.RequestFeature(LocomotionFeatureAITags::Teleporter, SubTagAITeleporter::ChaseDisappear, EBasicBehaviourPriority::Medium, this);

	 	bTeleporting = false;
		TeleportTime = Time::GameTimeSeconds + TeleporterSettings.TeleportChaseReappearDuration;	
		ReappearTime = BIG_NUMBER;
		SettleTime = BIG_NUMBER;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Owner.SetActorHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float CurTime = Time::GameTimeSeconds;
		if (!bTeleporting && (CurTime > TeleportTime))
		{
			bTeleporting = true;
			Owner.SetActorHiddenInGame(true);

			if(HasControl())
			{
				FVector TeleportLocation;
				if (!FindTeleportLocation(TeleportLocation))
				{
					// Couldn't find a location to teleport to, try again in a while
					// Owner.TriggerEffectEvent(n"TeleportChase.TeleportFail"); // UNKNOWN EFFECT EVENT NAMESPACE
					Cooldown.Set(1.0);
					return;				
				}
				
				FRotator TeleportRotation = (TargetComp.Target.ActorCenterLocation - TeleportLocation).Rotation();
				CrumbTeleport(TeleportLocation, TeleportRotation);		
			}
			
			return;
		}

		if (CurTime > ReappearTime)
		{
			Owner.SetActorHiddenInGame(false);
		 	AnimComp.RequestFeature(LocomotionFeatureAITags::Teleporter, SubTagAITeleporter::ChaseReappear, EBasicBehaviourPriority::Medium, this);
			// Owner.TriggerEffectEvent(n"TeleportChase.TeleportReappear"); // UNKNOWN EFFECT EVENT NAMESPACE
			ReappearTime = BIG_NUMBER;
			SettleTime = CurTime + TeleporterSettings.TeleportChasePostAppearanceDuration; 
		}

		if (CurTime > SettleTime)
		{
			// We're done, let other behaviour have a chance to do stuff
			Cooldown.Set(TeleporterSettings.TeleportChaseCooldown);
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTeleport(FVector Location, FRotator Rotation)
	{
		// Smooth teleport over time, in case we want to attach a teleport movement effect 
		Owner.SmoothTeleportActor(Location, Rotation, this, TeleporterSettings.TeleportChaseReappearDuration);
		ReappearTime = Time::GameTimeSeconds + TeleporterSettings.TeleportChaseReappearDuration;
	}

	bool FindTeleportLocation(FVector& TeleportLocation)
	{
		// Appear towards target with some scatter. Currently depends on worldup, fix if necessary.
		FVector TargetLoc = TargetComp.Target.ActorCenterLocation;
		FVector FromTargetDir = (Owner.ActorCenterLocation - TargetLoc).GetSafeNormal2D();
		float ScatterDegrees = Math::RandRange(-TeleporterSettings.TeleportChaseScatter, TeleporterSettings.TeleportChaseScatter);
		FVector ScatteredLoc = TargetLoc + FromTargetDir.RotateAngleAxis(ScatterDegrees, FVector::UpVector) * TeleporterSettings.TeleportChaseMinRange;
		if (Pathfinding::FindNavmeshLocation(ScatteredLoc, PathfollowingSettings.NavmeshMaxProjectionRange, GroundPathfollowingSettings.NavmeshMaxProjectionHeight, TeleportLocation))
			return true;
		
		// Falied to get a path location
		return true;
	}
}