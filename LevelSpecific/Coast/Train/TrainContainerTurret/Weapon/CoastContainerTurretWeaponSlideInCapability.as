class UCoastContainerTurretWeaponSlideInCapability : UBasicBehaviour
{
	default CompoundNetworkSupport = EHazeCompoundNetworkSupport::LocalOrCrumbNetwork;

	UCoastContainerTurretSettings Settings;
	UCoastContainerTurretWeaponSlideComponent SlideComp;
	UCoastContainerTurretDoorComponent TurretDoorComp;

	FVector TargetLocation;
	FHazeAcceleratedVector LocationAcc;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Super::Setup();
		Settings = UCoastContainerTurretSettings::GetSettings(Owner);
		SlideComp = UCoastContainerTurretWeaponSlideComponent::GetOrCreate(Owner);
		TurretDoorComp = UCoastContainerTurretDoorComponent::GetOrCreate(SlideComp.Weapon.Turret);
		TargetLocation = SlideComp.Weapon.Turret.WeaponComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!Super::ShouldActivate())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Super::ShouldDeactivate())
			return true;
		if(ActiveDuration > Settings.SlideInDuration)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Super::OnActivated();
		LocationAcc.Value = SlideComp.Weapon.Turret.WeaponComp.RelativeLocation;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Super::OnDeactivated();
		SlideComp.Weapon.Turret.WeaponComp.RelativeLocation = TargetLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		LocationAcc.AccelerateTo(TargetLocation, Settings.SlideInDuration, DeltaTime);
		SlideComp.Weapon.Turret.WeaponComp.RelativeLocation = LocationAcc.Value;
	}
}