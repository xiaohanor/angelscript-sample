class UFlyingCarPilotCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(FlyingCarTags::FlyingCarPilot);

	default TickGroup = EHazeTickGroup::BeforeMovement;
	default TickGroupOrder = 100;

	USkylineFlyingCarPilotComponent PilotComponent;
	UPlayerVFXSettingsComponent VFXSettingsComp;
	ASkylineFlyingCar Car;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PilotComponent = USkylineFlyingCarPilotComponent::Get(Owner);
		VFXSettingsComp = UPlayerVFXSettingsComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PilotComponent.Car == nullptr)
	        return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PilotComponent.Car == nullptr)
	        return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Car = PilotComponent.Car;

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(CapabilityTags::Visibility, this);

		Player.AttachToComponent(Car.Mesh);

		CapabilityInput::LinkActorToPlayerInput(Car, Player);

		Car.OnCollision.AddUFunction(this, n"OnCollision");

		VFXSettingsComp.RelevantAttachRoot.Apply(Car.Mesh, this);

		//Player.ApplySettings(FlyingCarVehicleChaseSettings, this);
		//Player.PlaySlotAnimation(Animation = Pilot.Car.PilotMh, bLoop = true);
		//Player.DisableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(CapabilityTags::Visibility, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		VFXSettingsComp.RelevantAttachRoot.Clear(this);

		if(Car != nullptr)
		{
			Car.OnCollision.UnbindObject(this);

			CapabilityInput::LinkActorToPlayerInput(PilotComponent.Car, nullptr);

			Car.YawInput = 0.0;
			Car.PitchInput = 0.0;

			Car = nullptr;
		}

		//Player.StopAnimationByAsset(Pilot.Car.PilotMh);
		//Player.EnableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if EDITOR
		if (PilotComponent.bSteeringOverridenByGunner)
			return;
#endif

		float InvertValue = Player.IsSteeringPitchInverted() ? -1 : 1;
		FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

		Car.YawInput = RawStick.Y;
		Car.PitchInput = RawStick.X * InvertValue;
		Car.bWasJumpActionStarted = WasActionStarted(ActionNames::MovementJump);
	}

	UFUNCTION()
	private void OnCollision(FSkylineFlyingCarCollision Collision)
	{
		TSubclassOf<UCameraShakeBase> CameraShake = Collision.Type == ESkylineFlyingCarCollisionType::TotalLoss ?
			Car.FatalCollisionCameraShake :
			Car.LightCollisionCameraShake;

		Player.PlayCameraShake(CameraShake, this);
		Player.PlayForceFeedback(Car.ImpactForceFeedback, false, false, this, 1.0);

	}
}