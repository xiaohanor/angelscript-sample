
class UWingSuitPlayerInputCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Wingsuit");
	default CapabilityTags.Add(n"WingsuitMovement");
	default CapabilityTags.Add(CapabilityTags::MovementInput);

	default TickGroup = EHazeTickGroup::Input;
	default TickGroupOrder = 90;

	default DebugCategory = n"Wingsuit";

	UWingSuitPlayerComponent WingSuitComp;
	UPlayerMovementComponent MoveComp;
	UWingSuitSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WingSuitComp = UWingSuitPlayerComponent::Get(Player);
		Settings = UWingSuitSettings::GetSettings(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WingSuitComp.bWingsuitActive)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WingSuitComp.bWingsuitActive)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CapabilityTags::StickInput, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::StickInput, this);
		Player.ClearMovementInput(this);
		WingSuitComp.WantedBarrelRollDirection = 0;
		WingSuitComp.BarrelRollCooldownTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		WingSuitComp.WantedBarrelRollDirection = 0;
		if(WingSuitComp.ActiveBarrelRollDirection != 0)
		{
			WingSuitComp.BarrelRollCooldownTime = Settings.BarrelRollCooldownTime;
		}
		else if(WingSuitComp.BarrelRollCooldownTime > 0)
		{
			WingSuitComp.BarrelRollCooldownTime -= DeltaTime;
		}
		else
		{
			WingSuitComp.WantedBarrelRollDirection = 0;
			if(WasActionStarted(ActionNames::MovementDash))
			{
				int Direction = int(Math::Sign(RawStick.Y));
				// Always barrel roll when dashing, even when we aren't doing any input
				if(Direction == 0)
					Direction = 1;

				WingSuitComp.WantedBarrelRollDirection = Direction;
				// -1 är left
				Player.PlayForceFeedback(WingSuitComp.ForceFeedbackBarrelRoll, this);
				Player.PlayCameraShake(WingSuitComp.CamShakeBarrelRoll, this);
			}
		}

		float InvertValue = Player.IsSteeringPitchInverted() ? -1 : 1;

		Player.ApplyMovementInput(FVector(0.0, RawStick.Y, RawStick.X * InvertValue), this);
		WingSuitComp.CurrentCameraForward = Player.GetViewRotation().ForwardVector;


	}
}