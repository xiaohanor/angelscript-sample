class USanctuaryGhostCameraTiltCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;
	USanctuaryGhostAttackResponseComponent AttackResponseComp;
	UCameraUserComponent CameraUserComp;

	float Rate = 0.15;
	float RateBackWards = 1.0;

	float TiltAlpha = 0.0;
	float Tilt = 0.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		AttackResponseComp = USanctuaryGhostAttackResponseComponent::Get(Player);
		CameraUserComp = UCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!AttackResponseComp.bIsAttacked.Get())
			return false;

		if(!AttackResponseComp.bIsLifted.Get())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (AttackResponseComp.bIsAttacked.Get())
			return false;

		if(TiltAlpha<KINDA_SMALL_NUMBER)
			return true;


		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Tilt = 0.0;
		Player.BlockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraAlignWithWorldUp, this);
		CameraUserComp.ClearYawAxis(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (AttackResponseComp.bIsAttacked.Get())
			Tilt += DeltaTime * Rate;
		else
			Tilt -= DeltaTime * RateBackWards;

		
		Tilt = Math::Clamp(Tilt, SMALL_NUMBER, 1.0);

		if (AttackResponseComp.bIsAttacked.Get())
			TiltAlpha = Tilt;
		else
			TiltAlpha = Math::FInterpConstantTo(TiltAlpha, 0.0, DeltaTime, 1.0);
			
		FVector WorldUp = Player.MovementWorldUp;
		FVector ForwardAlongGround = WorldUp.CrossProduct(CameraUserComp.ViewRotation.RightVector);
		FVector NewYawAxis = WorldUp.RotateAngleAxis(TiltAlpha * 55.0, ForwardAlongGround);
		CameraUserComp.SetYawAxis(NewYawAxis, this);

		
		if (!AttackResponseComp.bIsAttacked.Get())
			Tilt = 0.0;
	}
};