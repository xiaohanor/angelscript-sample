class UDentistBossToolDenturesRidingCameraOffsetCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Camera);

	default TickGroup = EHazeTickGroup::Gameplay;

	ADentistBossToolDentures Dentures;
	ADentistBoss Dentist;
	AHazePlayerCharacter Player;

	UCameraUserComponent CameraUserComp;

	UDentistBossSettings Settings;

	FHazeAcceleratedVector AccCameraOffset;
	UCameraSettings CameraSettings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Dentures = Cast<ADentistBossToolDentures>(Owner);
		Dentist = TListedActors<ADentistBoss>().GetSingle();

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentures.bDestroyed)
			return false;

		if(!Dentures.ControllingPlayer.IsSet())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Dentures.bDestroyed)
			return true;

		if(!Dentures.ControllingPlayer.IsSet())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Dentures.ControllingPlayer.Value;
		CameraUserComp = UCameraUserComponent::Get(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);

		AccCameraOffset.SnapTo(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearCameraSettingsByInstigator(this, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector WobbleLocation = (Dentures.InteractComp.WorldLocation - Dentures.SkelMesh.WorldLocation).ConstrainToPlane(Player.ActorForwardVector);
		WobbleLocation -= FVector::UpVector * 200;
		AccCameraOffset.AccelerateTo(WobbleLocation, 0.5, DeltaTime);
		CameraSettings.CameraOffset.ApplyAsAdditive(AccCameraOffset.Value, this, 0.0);
	}
};