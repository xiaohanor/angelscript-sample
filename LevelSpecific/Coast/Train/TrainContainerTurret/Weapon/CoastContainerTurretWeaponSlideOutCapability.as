class UCoastContainerTurretWeaponSlideOutCapability : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UCoastContainerTurretSettings Settings;
	UCoastContainerTurretWeaponSlideComponent SlideComp;
	UCoastContainerTurretDoorComponent TurretDoorComp;

	FVector TargetLocation;
	FHazeAcceleratedVector LocationAcc;
	float CooldownTime;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastContainerTurretSettings::GetSettings(Owner);
		SlideComp = UCoastContainerTurretWeaponSlideComponent::GetOrCreate(Owner);
		TurretDoorComp = UCoastContainerTurretDoorComponent::GetOrCreate(SlideComp.Weapon.Turret);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		if(CooldownTime != 0 && Time::GetGameTimeSince(CooldownTime) < Settings.SlideOutCooldown)
			return false;
		if(TargetComp.Target == nullptr)
			return false;
		if(!TurretDoorComp.IsOpen)
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.SlideOutDuration)
			return true;
		if(!TurretDoorComp.IsOpen)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		LocationAcc.Value = SlideComp.Weapon.Turret.WeaponComp.RelativeLocation;
		TargetLocation = SlideComp.Weapon.Turret.WeaponComp.RelativeLocation + FVector::RightVector * Settings.SlideOutDistance;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SlideComp.Weapon.Turret.WeaponComp.RelativeLocation = TargetLocation;
		CooldownTime = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LocationAcc.AccelerateTo(TargetLocation, Settings.SlideOutDuration, DeltaTime);
		SlideComp.Weapon.Turret.WeaponComp.RelativeLocation = LocationAcc.Value;
	}
}