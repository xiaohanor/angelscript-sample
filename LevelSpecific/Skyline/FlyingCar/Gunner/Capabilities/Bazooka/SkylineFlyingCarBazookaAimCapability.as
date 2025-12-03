class USkylineFlyingCarBazookaAimCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(FlyingCarTags::FlyingCarGunner);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::LastMovement;

	USkylineFlyingCarGunnerComponent GunnerComponent;
	UPlayerTargetablesComponent TargetablesComponent;
	UPlayerAimingComponent AimingComponent;

	USkylineFlyingCarBazookaTargetableComponent PreviousPrimaryTarget;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		TargetablesComponent = UPlayerTargetablesComponent::Get(Owner);
		AimingComponent = UPlayerAimingComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GunnerComponent.Car == nullptr)
			return false;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Bazooka)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GunnerComponent.Car == nullptr)
			return true;

		if (GunnerComponent.GetGunnerState() != EFlyingCarGunnerState::Bazooka)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		PreviousPrimaryTarget = nullptr;

		FAimingSettings Settings;
		Settings.OverrideCrosshairWidget = GunnerComponent.BazookaWidgetData.CrosshairWidget;
		Settings.bShowCrosshair = true;
		Settings.bCrosshairFollowsTarget = false;
		Settings.CrosshairLingerDuration = 0.0;
		AimingComponent.StartAiming(this, Settings);

		// Display weapon
		GunnerComponent.Bazooka.SetActorHiddenInGame(false);
		GunnerComponent.FakeBazookaMeshComponent.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimingComponent.StopAiming(this);

		GunnerComponent.Bazooka.SetActorHiddenInGame(true);
		GunnerComponent.FakeBazookaMeshComponent.SetHiddenInGame(false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TargetablesComponent.ShowWidgetsForTargetables(USkylineFlyingCarBazookaTargetableComponent);

		auto PrimaryTarget = TargetablesComponent.GetPrimaryTarget(USkylineFlyingCarBazookaTargetableComponent);
		if (PrimaryTarget != nullptr)
		{
			// Setup new primary
			if (PrimaryTarget != PreviousPrimaryTarget)
			{
				if (PreviousPrimaryTarget != nullptr)
					PreviousPrimaryTarget.LosePrimaryStatus();

				PrimaryTarget.GainPrimaryStatus();
				PreviousPrimaryTarget = PrimaryTarget;
			}

			// Update aiming
			PrimaryTarget.bPlayerAimingDown = GunnerComponent.bIsInAimDown;
		}
		else
		{
			if (PreviousPrimaryTarget != nullptr)
			{
				PreviousPrimaryTarget.LosePrimaryStatus();
				PreviousPrimaryTarget = nullptr;
			}
		}

		// Update animation blend spaces
		GunnerComponent.UpdateBlendSpaceValues();

		// Animate lady
		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(n"FlyingCarGunnerBazooka", this);
	}
}