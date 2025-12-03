class USkylineSentryDroneTurretFireCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SkylineSentryDroneTurretFire");
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

		if(DeactiveDuration < Settings.FireInterval)
			return false;

		if(!CanShoot())
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
	//	Debug::DrawDebugLine(TurretComponent.WorldLocation, TurretComponent.WorldLocation + TurretComponent.ForwardVector * 3000.0, FLinearColor::Red, 10.0, 0.2);
		TurretComponent.Fire();
	}

	bool CanShoot() const
	{
		if (Settings.bFireWhenSlinged && GravityWhipResponseComponent.Grabs.Num() > 0)
			return true;

		if(TurretComponent.CurrentTarget == nullptr)
			return false;

		FVector AimDirection = (TurretComponent.CurrentTarget.ActorCenterLocation - TurretComponent.WorldLocation).GetSafeNormal();

		float ToTargetDot = TurretComponent.ForwardVector.DotProduct(AimDirection);

//		PrintToScreen("ToTargetDot:" + ToTargetDot, 1.0);

		if (ToTargetDot > 0.99)
		{
			return true;
		}

		return false;
	}

}