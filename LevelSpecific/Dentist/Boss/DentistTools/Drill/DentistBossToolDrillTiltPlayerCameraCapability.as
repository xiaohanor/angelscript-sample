class UDentistBossToolDrillTiltPlayerCameraCapability : UHazePlayerCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	default NetworkMode = EHazeCapabilityNetworkMode::Local;

	ADentistBoss Dentist;
	ADentistBossToolDrill Drill;
	UDentistBossTargetComponent TargetComp;

	UCameraUserComponent CameraUserComp;

	UDentistBossSettings Settings;

	float TiltAlpha = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CameraUserComp = UCameraUserComponent::Get(Player);

		Drill = TListedActors<ADentistBossToolDrill>().Single;
		Dentist = TListedActors<ADentistBoss>().Single;
		TargetComp = UDentistBossTargetComponent::Get(Dentist);

		Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(Dentist == nullptr)
			return false;

		if(Settings == nullptr)
			return false;

		if(Drill == nullptr)
			return false;

		if(Drill.TargetedPlayer != Player)
			return false;

		if(!TargetComp.bIsDrilling)
			return false;
		
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(TiltAlpha == 0)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		CameraUserComp.ClearYawAxis(this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Dentist == nullptr)
			Dentist = TListedActors<ADentistBoss>().Single;

		if(Drill == nullptr)
			Drill = TListedActors<ADentistBossToolDrill>().Single;
		
		if(Dentist == nullptr)
			return;
			
		if(TargetComp == nullptr)
			TargetComp = UDentistBossTargetComponent::Get(Dentist);
		
		if(Settings == nullptr)
			Settings = UDentistBossSettings::GetSettings(Dentist);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TargetComp.bIsDrilling
		&& Drill.TargetedPlayer == Player)
			TiltAlpha = Drill.DrillAlpha;
		else
			TiltAlpha = Math::FInterpConstantTo(TiltAlpha, 0.0, DeltaTime, Settings.BeingDrilledCameraTiltGoBackSpeed);

		FVector WorldUp = Player.MovementWorldUp;
		FVector ForwardAlongGround = WorldUp.CrossProduct(CameraUserComp.ViewRotation.RightVector);
		FVector NewYawAxis = WorldUp.RotateAngleAxis(TiltAlpha * Settings.BeingDrilledCameraTiltDegreesMax, ForwardAlongGround);
		CameraUserComp.SetYawAxis(NewYawAxis, this);
	}
};