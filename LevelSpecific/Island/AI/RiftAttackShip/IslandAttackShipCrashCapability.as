struct FIslandAttackShipCrashCapabilityParams
{
	AIslandAttackShipCrashpointActor Crashpoint;
	bool bIsTriggerCrashpoint = false;
}

class UIslandAttackShipCrashCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	AAIIslandAttackShip AttackShip;
	UBasicAIDestinationComponent DestComp;
	UBasicAITargetingComponent TargetComp;
	UHazeActorRespawnableComponent RespawnComp;

	FRuntimeFloatCurve Speed;	
	default Speed.AddDefaultKey(0.0, 0.0);
	default Speed.AddDefaultKey(0.1, 0.05);
	default Speed.AddDefaultKey(0.2, 0.4);
	default Speed.AddDefaultKey(0.3, 0.1);
	default Speed.AddDefaultKey(0.5, 0.8);
	default Speed.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere)
	FRuntimeFloatCurve Rotation;
	default Rotation.AddDefaultKey(0.0, 0.0);
	default Rotation.AddDefaultKey(1.0, 1.0);


	FHazeRuntimeSpline Spline;

	UIslandAttackShipSettings Settings;

	bool bHasValidSpline = false;
	bool bHasCrashed = false;
	bool bHasTriggeredVFX = false;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DestComp = UBasicAIDestinationComponent::Get(Owner);
		TargetComp = UBasicAITargetingComponent::Get(Owner);
		RespawnComp = UHazeActorRespawnableComponent::Get(Owner);
		RespawnComp.OnRespawn.AddUFunction(this, n"OnRespawn");
		AttackShip = Cast<AAIIslandAttackShip>(Owner);
		Settings = UIslandAttackShipSettings::GetSettings(Owner);
	}

	UFUNCTION()
	private void OnRespawn()
	{
		Owner.RemoveActorDisable(this);
		bHasCrashed = false;
		bHasTriggeredVFX = false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FIslandAttackShipCrashCapabilityParams& Params) const
	{
		if (AttackShip == nullptr)
			return false;
		if (!AttackShip.bHasPilotDied)
			return false;
		
		// Ensure that boths sides use the same crashpoint.
		bool bIsTrigger = false;
		AIslandAttackShipCrashpointActor ClosestCrashpoint;
		if (!AttackShip.CurrentManager.IsLastTeamMember(AttackShip))
		{
			IslandAttackShip::GetClosestNonTriggerCrashpoint(Owner, ClosestCrashpoint);
		}
		else
		{
			IslandAttackShip::GetClosestTriggerCrashpoint(Owner, ClosestCrashpoint);
			bIsTrigger = true;
		}
		Params.Crashpoint = ClosestCrashpoint;
		Params.bIsTriggerCrashpoint = bIsTrigger;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!bHasValidSpline)
			return true;
		if (!AttackShip.bHasPilotDied)
			return true;
		if (bHasCrashed)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FIslandAttackShipCrashCapabilityParams Params)
	{
		UIslandAttackShipEffectHandler::Trigger_OnStartCrashTrajectory(Owner, FIslandAttackShipOnStartCrashTrajectoryParams(AttackShip.MeshOffsetComponent));
		
		Params.Crashpoint.bIsUsed = true;
		
		if (Params.bIsTriggerCrashpoint)
		{
			// POI
			FApplyPointOfInterestSettings POISettings;
			POISettings.Duration = Settings.CrashPOIDuration;
			POISettings.RegainInputTime = Settings.CrashPOIRegainInputTime;
			FHazePointOfInterestFocusTargetInfo FocusTarget;
			FocusTarget.SetFocusToActor(Owner);
			FocusTarget.SetWorldOffset(Settings.CrashPOIFocusTargetOffset);
			Game::Mio.ApplyPointOfInterest(this, FocusTarget, POISettings);
			Game::Zoe.ApplyPointOfInterest(this, FocusTarget, POISettings);
		}
		else
		{
			// Report unspawned in advance to permit trigger crash point to signal the OnWipedOut event on the only relevant crash impact.
			AttackShip.CurrentManager.ReportUnspawned(AttackShip);
		}


		// Try set TargetLocation
		FVector TargetLocation;
		if (Params.Crashpoint != nullptr)
		{
			TargetLocation = Params.Crashpoint.ActorLocation;
		}		
		else
		{
			// Fallback location used if no crashpoints are deployed.
			TargetLocation = Owner.ActorLocation - FVector(Math::RandRange(-1000, 1000), Math::RandRange(-1000, 1000), 5000);
		}

		// Create runtimespline for move trajectory
		// This, currently, does not consider walls or other obstacles
		Spline = FHazeRuntimeSpline();
		Spline.AddPoint(Owner.ActorLocation); // Start
		Spline.AddPoint(Owner.ActorLocation - Owner.ActorForwardVector * -100.0); // Start

		// If destination is further away, add some curvature
		FVector ToTargetLocation = (TargetLocation - Owner.ActorLocation);
		if (Params.Crashpoint != nullptr && Params.Crashpoint.CrashReroute.WorldLocation.DistSquared(Params.Crashpoint.ActorLocation) > 100 * 100)
		{
			FVector InterPoint = Params.Crashpoint.CrashReroute.WorldLocation;
			Spline.AddPoint(InterPoint);
		}
		else if (ToTargetLocation.SizeSquared() > 1000*1000) // Minimum distance
		{
			FVector InterPoint = Owner.ActorLocation + ToTargetLocation * 0.75;
			InterPoint.Z = Owner.ActorLocation.Z + (TargetLocation.Z - Owner.ActorLocation.Z) * 0.33; // Height offset
			Spline.AddPoint(InterPoint);
		}		
		
		Spline.AddPoint(TargetLocation); // End
		
		DistanceAlongSpline = 0;
		bHasValidSpline = true;
		if (Spline.GetLength() < SMALL_NUMBER)
			bHasValidSpline = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Mio.ClearPointOfInterestByInstigator(this);
		Game::Zoe.ClearPointOfInterestByInstigator(this);
		if (AttackShip.CurrentManager != nullptr)
			AttackShip.CurrentManager.ReportUnspawned(AttackShip);
		Owner.AddActorDisable(this);
		if (!bHasTriggeredVFX)
			UIslandAttackShipEffectHandler::Trigger_OnCrashImpact(Owner, FIslandAttackShipOnCrashImpactParams(Owner.ActorCenterLocation, Owner.ActorForwardVector * -1.0));
	}

	float DistanceAlongSpline = 0;
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Follow spline
		if(!bHasValidSpline)
			return;
		
		DistanceAlongSpline += Settings.CrashBaseSpeed + Settings.CrashMaxSpeedIncrement * Speed.GetFloatValue(DistanceAlongSpline/Spline.GetLength()) * DeltaTime;

		if (!bHasTriggeredVFX && DistanceAlongSpline > Spline.GetLength() - 200)
		{
			UIslandAttackShipEffectHandler::Trigger_OnCrashImpact(Owner, FIslandAttackShipOnCrashImpactParams(Owner.ActorCenterLocation, Owner.ActorForwardVector * -1.0));
			bHasTriggeredVFX = true;
			return;
		}
		else if (DistanceAlongSpline > Spline.GetLength() - 50)
		{
			bHasCrashed = true;
			return;
		}

		float SplineAlpha = DistanceAlongSpline/Spline.GetLength();
		FVector NewLocation = Spline.GetLocation(SplineAlpha);		

		float RotationScale = Rotation.GetFloatValue(SplineAlpha);
		Owner.AddActorLocalRotation(FRotator(Math::RandRange(-200, 200), Math::RandRange(-200, 200), Math::RandRange(150.1, 410.0) ) * RotationScale * DeltaTime);
		Owner.SetActorLocation(NewLocation);
	}

};