class USkylineSentryDroneImpactCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineDroneImpact");

	UHazeMovementComponent MovementComponent;

	USweepingMovementData Movement;

	ASkylineSentryDrone SentryDrone;

	USkylineSentryDroneSettings Settings;

	float ImpactSpeedThreshold = 5.0;

	float ImpactCooldown = 0.05;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Settings = USkylineSentryDroneSettings::GetSettings(Owner);

		MovementComponent = UHazeMovementComponent::Get(Owner);
		Movement = MovementComponent.SetupSweepingMovementData();

		SentryDrone = Cast<ASkylineSentryDrone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (DeactiveDuration < ImpactCooldown)
			return false;

		if (!MovementComponent.HasAnyValidBlockingContacts())
			return false;

		if (MovementComponent.PreviousVelocity.Size() < ImpactSpeedThreshold)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PrintToScreen("Impact", 0.0, FLinearColor::Green);

		if (SentryDrone.bIsThrown && Settings.bExplodeOnImpact)
			SentryDrone.Explode();

		auto HitResults = GetImpacts();
		if (HitResults.Num() > 0 && HitResults[0].bBlockingHit)
		{
			Owner.ActorVelocity = Math::GetReflectionVector(MovementComponent.PreviousVelocity, HitResults[0].Normal) * Settings.ImpactRestitution;
		
			SentryDrone.AngularVelocity += SentryDrone.ActorTransform.InverseTransformVectorNoScale(HitResults[0].ImpactNormal.CrossProduct(MovementComponent.PreviousVelocity) * Settings.ImpactAngularSpeed);
		
			if (Owner.ActorVelocity.Size() > 100.0)
				USkylineSentryDroneEventHandler::Trigger_Impact(Owner, HitResults[0]);
		
			if (!SentryDrone.bHadImpact)
			{
				SentryDrone.bHadImpact = true;
				SentryDrone.DisableTime = 4.0;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	TArray<FHitResult> GetImpacts()
	{
		TArray<FHitResult> HitResults;

		if (MovementComponent.HasGroundContact())
			HitResults.Add(MovementComponent.GroundContact.ConvertToHitResult());

		if (MovementComponent.HasWallContact())
			HitResults.Add(MovementComponent.WallContact.ConvertToHitResult());

		if (MovementComponent.HasCeilingContact())
			HitResults.Add(MovementComponent.CeilingContact.ConvertToHitResult());

		return HitResults;
	}
}