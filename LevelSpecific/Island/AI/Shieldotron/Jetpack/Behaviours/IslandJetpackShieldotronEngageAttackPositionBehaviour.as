class UIslandJetpackShieldotronEngageAttackPositionBehaviour : UBasicBehaviour
{
	// Movement only (which is replicated separately)
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::ActivatesOnControlOnly;

	default Requirements.Add(EBasicBehaviourRequirement::Movement);

	UIslandJetpackShieldotronHoldWaypointComponent WaypointComp;

	UIslandJetpackShieldotronSettings JetpackSettings; 
	UBasicAIResourceManager Resources;
	float MaxDuration;

	float CheckGeometryInterval = 0.1;
	float CheckGeometryTime;

	AHazeActor Target;
	FVector Destination;
	FVector InitialPosition;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		JetpackSettings =  UIslandJetpackShieldotronSettings::GetSettings(Owner);
		WaypointComp = UIslandJetpackShieldotronHoldWaypointComponent::GetOrCreate(Owner);
		Resources = Game::GetSingleton(UBasicAIResourceManager);
		InitialPosition = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Super::ShouldActivate())
			return false;
		if (!TargetComp.HasValidTarget())
			return false;
		if (WaypointComp.Waypoint != nullptr)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate())
			return true;
		if (ActiveDuration > MaxDuration)
			return true;
		if (!TargetComp.IsValidTarget(Target))
			return true;
		if (WaypointComp.Waypoint != nullptr)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		MaxDuration = Math::RandRange(2, 3);
		Target = TargetComp.Target;
		AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(Target);

		Destination = Owner.ActorLocation;
		float RadiusFactor = Math::GetMappedRangeValueClamped(FVector2D(0, 2000),FVector2D(0.5, 1.5), Target.ActorVelocity.Size());
		float Radius = Math::RandRange(3000, 4000) * RadiusFactor;
		FVector ViewRot2D = PlayerTarget.GetViewRotation().ForwardVector.GetSafeNormal2D();
		FVector ViewDir2D = Math::GetRandomConeDirection(ViewRot2D, PI * 0.25);
		ViewDir2D = ViewDir2D.GetSafeNormal2D();
		Destination = Target.ActorCenterLocation + (ViewDir2D * Radius);
		float MaxHeight = 800;
		
		Destination.Z = Math::Clamp(Destination.Z + Math::RandRange(200, MaxHeight), Target.ActorLocation.Z, Target.ActorLocation.Z + MaxHeight);
		
		CheckGeometryTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		Cooldown.Set(Math::RandRange(JetpackSettings.EngageAttackPositionCooldownMin, JetpackSettings.EngageAttackPositionCooldownMax));
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float SpeedFactor = 1.0;
		float DistSqr = 1000*1000;
		if (Destination.DistSquared(Owner.ActorLocation) > DistSqr)
			SpeedFactor = Math::GetMappedRangeValueClamped(FVector2D(0, 2000),FVector2D(1.0, 2.5), Target.ActorVelocity.Size());
		else
			SpeedFactor = Math::GetMappedRangeValueClamped(FVector2D(0, DistSqr), FVector2D(0.25, 1), Destination.DistSquared(Owner.ActorLocation));
		DestinationComp.MoveTowards(Destination, JetpackSettings.HoverChaseMoveSpeed * SpeedFactor);		
		if (Destination.IsWithinDist(Owner.ActorCenterLocation, 200 * SpeedFactor) )
			DeactivateBehaviour(); // Will set cooldown in OnDeactivated.

		//Debug::DrawDebugLine(Target.ActorLocation, FVector(Destination.X, Destination.Y, Target.ActorLocation.Z), FLinearColor::Red, Duration = 3.0, bDrawInForeground = true);

		if ((Time::GameTimeSeconds > CheckGeometryTime) && Resources.CanUse(EAIResource::NavigationTrace))
		{
			Resources.Use(EAIResource::NavigationTrace);
			//if(Navigation::NavOctreeLineTrace(Owner.ActorLocation, Destination))
			//	DeactivateBehaviour();
			CheckGeometryTime = Time::GetGameTimeSeconds() + CheckGeometryInterval;
		}
	}

#if EDITOR
	void DebugDraw(float Radius)
	{
		Debug::DrawDebugCircle(Target.ActorCenterLocation, Radius, Duration = 3.0);
		Debug::DrawDebugSphere(Destination, 40, 12, FLinearColor::Blue, Duration = 3.0);
		Debug::DrawDebugLine(Target.ActorCenterLocation, Destination, FLinearColor::Red, Duration = 3.0, bDrawInForeground = true);		
		Debug::DrawDebugSphere(Destination, 40, 12, FLinearColor::LucBlue, Duration = 3.0);
	}
#endif
}
