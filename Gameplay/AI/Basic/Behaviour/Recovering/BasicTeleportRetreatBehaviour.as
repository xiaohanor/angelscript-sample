class UBasicTeleportRetreatBehaviour : UBasicBehaviour
{
	default Requirements.Add(EBasicBehaviourRequirement::Movement);
	default Requirements.Add(EBasicBehaviourRequirement::Animation);

	UBasicAITeleporterSettings TeleporterSettings;
	UPathfollowingSettings PathfollowingSettings;
	UGroundPathfollowingSettings GroundPathfollowingSettings;

	bool bTeleporting = false;
	float TeleportTime;
	float ReappearTime;

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

		// Owner.TriggerEffectEvent(n"TeleportRetreat.TeleportDisappear"); // UNKNOWN EFFECT EVENT NAMESPACE

		// if (TeleporterSettings.TeleportRetreatTelegraphDuration > 0.0)
		// 	AnimComp.RequestFeature(,);

	 	bTeleporting = false;
		TeleportTime = Time::GameTimeSeconds + TeleporterSettings.TeleportRetreatReappearDuration;	
		ReappearTime = BIG_NUMBER;
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
		if (!bTeleporting && (Time::GameTimeSeconds > TeleportTime))
		{
			bTeleporting = true;
			Owner.SetActorHiddenInGame(true);

			FVector TeleportLocation;
			if (!FindTeleportLocation(TeleportLocation))
			{
				// Couldn't find a location to teleport to, skip recovery
				// Owner.TriggerEffectEvent(n"TeleportRetreat.TeleportFail"); // UNKNOWN EFFECT EVENT NAMESPACE
				return;				
			}
			
			FRotator TeleportRotation = (TargetComp.Target != nullptr) ? (TargetComp.Target.ActorCenterLocation - TeleportLocation).Rotation() : Owner.ActorRotation;
			CrumbTeleport(TeleportLocation, TeleportRotation);		
			return;
		}

		if (Time::GameTimeSeconds > ReappearTime)
		{
			//AnimComp.RequestFeature(, );
			// Owner.TriggerEffectEvent(n"TeleportRetreat.TeleportReappear"); // UNKNOWN EFFECT EVENT NAMESPACE
			ReappearTime = BIG_NUMBER;
			return;
		}
	}

	UFUNCTION(CrumbFunction)
	void CrumbTeleport(FVector Location, FRotator Rotation)
	{
		// Smooth teleport over time, in case we want to attach a teleport movement effect 
		Owner.SmoothTeleportActor(Location, Rotation, this, TeleporterSettings.TeleportRetreatReappearDuration);
		ReappearTime = Time::GameTimeSeconds + TeleporterSettings.TeleportRetreatReappearDuration;
	}

	bool FindTeleportLocation(FVector& TeleportLocation)
	{
		// Appear towards target with some scatter. Currently depends on worldup, fix if necessary.
		FVector AwayLoc = (TargetComp.Target != nullptr) ? TargetComp.Target.ActorCenterLocation : Owner.ActorCenterLocation + Owner.ActorForwardVector * 100.0;
		FVector AwayDir = (Owner.ActorCenterLocation - AwayLoc).GetSafeNormal2D();
		float ScatterDegrees = Math::RandRange(-TeleporterSettings.TeleportRetreatScatter, TeleporterSettings.TeleportRetreatScatter);
		FVector ScatteredLoc = AwayLoc + AwayDir.RotateAngleAxis(ScatterDegrees, FVector::UpVector) * TeleporterSettings.TeleportRetreatRange;
		if (Pathfinding::FindNavmeshLocation(ScatteredLoc, PathfollowingSettings.NavmeshMaxProjectionRange, GroundPathfollowingSettings.NavmeshMaxProjectionHeight, TeleportLocation))
			return true;
		
		// Falied to get a path location
		return true;
	}
}