class USkylineSentryDroneTurretTargetingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineSentryDroneTurretTargeting");
	default CapabilityTags.Add(n"SkylineSentryDroneTurret");

	USkylineSentryDroneTurretComponent TurretComponent;

	UGravityWhipResponseComponent GravityWhipResponseComponent;

	USkylineSentryDroneTurretSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineSentryDroneTurretSettings::GetSettings(Owner);

		TurretComponent = USkylineSentryDroneTurretComponent::Get(Owner);

		GravityWhipResponseComponent = UGravityWhipResponseComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (TurretComponent == nullptr)
			return false;

		if (!Settings.bUseTargetTracking)
			return false;

		if (!HasValidTarget())
			return false;
			
		return true;
		
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (TurretComponent == nullptr)
			return true;

		if (!Settings.bUseTargetTracking)
			return true;

		if (!HasValidTarget())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		TurretComponent.CurrentTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TurretComponent.CurrentTarget = GetTargetInRange();

		PrintToScreen("Target:" + TurretComponent.CurrentTarget);

		TurretComponent.AimDirection = (TurretComponent.CurrentTarget.ActorCenterLocation - TurretComponent.WorldLocation).GetSafeNormal();
	
	//	FQuat AimRotation = FQuat::Slerp(TurretComponent.ComponentQuat, FQuat::MakeFromX(AimDirection), DeltaTime * Settings.RotationSpeed);

	//	TurretComponent.SetWorldRotation(AimRotation);
	}

	bool HasValidTarget() const
	{
		return (GetTargetInRange() != nullptr);
	}

	AHazeActor GetTargetInRange() const
	{
	//	Debug::DrawDebugLine(TurretComponent.WorldLocation, TurretComponent.WorldLocation + Owner.ActorTransform.TransformVectorNoScale(TurretComponent.InitialDirection) * 300.0, FLinearColor::Blue, 30.0, 0.2);

		AHazeActor ClosestTarget;
		float ClosestDistance = Settings.Range;

		TArray<AHazeActor> Targets = TurretComponent.Targets;

		// Add the Teams to target array
		for (auto Team : TurretComponent.TargetTeams)
			Targets.Append(Team.GetMembers());

		for (auto Target : Targets)
		{
			// TEMP HACK
			if ((Target == Game::Mio || Target == Game::Zoe) && GravityWhipResponseComponent.Grabs.Num() > 0 && !Settings.bPlayerHostileWhenGrabbed)
				continue;

			FVector ToTarget = Target.ActorCenterLocation - TurretComponent.WorldLocation;

			float DistanceToTarget = ToTarget.Size();

			if (DistanceToTarget < ClosestDistance)
			{
				float TargetDot = ToTarget.GetSafeNormal().DotProduct(Owner.ActorTransform.TransformVectorNoScale(TurretComponent.InitialDirection));

				float Angle = Math::RadiansToDegrees(ToTarget.GetSafeNormal().AngularDistanceForNormals(Owner.ActorTransform.TransformVectorNoScale(TurretComponent.InitialDirection)));

				if (Angle <= Settings.Angle)
				{
					auto Trace = Trace::InitChannel(ECollisionChannel::ECC_Visibility);
					Trace.IgnoreActor(Owner);
					auto HitResult = Trace.QueryTraceSingle(TurretComponent.WorldLocation, Target.ActorCenterLocation);

					if (Settings.bIgnoreLineOfSightTrace || (HitResult.bBlockingHit && HitResult.Actor == Target))
					{
					//	PrintToScreen("TargetDot:" + TargetDot);

						ClosestTarget = Target;
						ClosestDistance = DistanceToTarget;
					}
				}
			}
		}

		return ClosestTarget;
	}

}