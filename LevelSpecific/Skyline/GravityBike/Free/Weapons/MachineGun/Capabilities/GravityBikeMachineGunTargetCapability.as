class UGravityBikeMachineGunTargetCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 80;

	UGravityBikeFreeDriverComponent DriverComp;
	UGravityBikeMachineGunComponent MachineGunComp;
	UPlayerAimingComponent AimComp;
	UPlayerTargetablesComponent TargetablesComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		DriverComp = UGravityBikeFreeDriverComponent::Get(Owner);
		MachineGunComp = UGravityBikeMachineGunComponent::Get(Owner);
		AimComp = UPlayerAimingComponent::Get(Owner);
		TargetablesComp = UPlayerTargetablesComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!MachineGunComp.IsEquipped())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!MachineGunComp.IsEquipped())
			return true;

		return false;	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplySettings(MachineGunComp.PlayerAimingSettings, this);

		FAimingSettings AimingSettings;
		AimingSettings.bShowCrosshair = false;
		AimingSettings.bApplyAimingSensitivity = false;
		AimingSettings.bUseAutoAim = true;
		AimComp.StartAiming(MachineGunComp, AimingSettings);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		AimComp.ClearAimingRayOverride(this);
		AimComp.StopAiming(MachineGunComp);

		Player.ClearSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FAimingRay OverrideAimingRay;
		OverrideAimingRay.Origin = Player.ActorCenterLocation;
		OverrideAimingRay.Direction = Player.ActorForwardVector;
		AimComp.ApplyAimingRayOverride(OverrideAimingRay, this);

		auto AimingRay = AimComp.GetPlayerAimingRay();

		auto AimingResult = AimComp.GetAimingTarget(MachineGunComp);

		if (AimingResult.AutoAimTarget != nullptr)
		{
			FGravityBikeWeaponTargetData TargetData;
			TargetData.TargetComponent = AimingResult.AutoAimTarget;
			MachineGunComp.AimTarget = TargetData;
		}
		else
		{
			auto Trace = Trace::InitChannel(ECollisionChannel::PlayerAiming);
			Trace.IgnorePlayers();
			Trace.IgnoreActor(DriverComp.GetGravityBike());
			auto HitResult = Trace.QueryTraceSingle(AimingRay.Origin, AimingRay.Origin + AimingRay.Direction * 500000.0);

			FVector EndLocation = HitResult.TraceEnd;

			if (HitResult.bBlockingHit)
			{
				EndLocation = HitResult.ImpactPoint;
				MachineGunComp.AimTarget = FGravityBikeWeaponTargetData(HitResult.Component, EndLocation);
			}
			else
			{
				MachineGunComp.AimTarget = FGravityBikeWeaponTargetData(EndLocation);
			}
		}
 	}
}