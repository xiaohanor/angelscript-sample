
class UFlyingCarGunnerCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(FlyingCarTags::FlyingCarGunner);

	default TickGroup = EHazeTickGroup::AfterGameplay;
	default TickGroupOrder = 100;

	USkylineFlyingCarGunnerComponent GunnerComponent;
	UPlayerVFXSettingsComponent VFXSettingsComp;
	UCameraUserComponent CameraUser;

	ASkylineFlyingCarGun Gun;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		GunnerComponent = USkylineFlyingCarGunnerComponent::Get(Owner);
		VFXSettingsComp = UPlayerVFXSettingsComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (GunnerComponent.Car == nullptr)
	        return false;

        return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (GunnerComponent.Car == nullptr)
	        return true;

        return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.AttachToComponent(GunnerComponent.Car.FakeCar, n"Base");
		Player.ApplyCameraSettings(GunnerComponent.CameraSettings, 2, this, EHazeCameraPriority::Low);
		CameraUser.SnapCamera(GunnerComponent.Car.GetActorForwardVector());

		Outline::ApplyNoOutlineOnActor(GunnerComponent.Car, Player, this, EInstigatePriority::Normal);

		// Push upwards, outside the sunroof
		FVector WindowOffset = FVector::UpVector * 100 - FVector::ForwardVector * 20;
		UCameraSettings::GetSettings(Player).CameraOffsetOwnerSpace.Apply(WindowOffset, this);

		Player.MeshOffsetComponent.SetTickEarlyAllowed(true);

		Gun = GunnerComponent.Car.Gun;

		GunnerComponent.Car.OnCollision.AddUFunction(this, n"OnCollision");

		Player.Mesh.SetRenderedForPlayer(Player.OtherPlayer, false);
		GunnerComponent.Car.FakeMio.SetLeaderPoseComponent(Game::Mio.Mesh);

		VFXSettingsComp.RelevantAttachRoot.Apply(GunnerComponent.Car.FakeCar, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		GunnerComponent.Car.OnCollision.UnbindObject(this);

		Outline::ClearOutlineOnActor(GunnerComponent.Car, Player, this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);	
		Player.ClearCameraSettingsByInstigator(this);
		VFXSettingsComp.RelevantAttachRoot.Clear(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
#if EDITOR
		if (WasActionStarted(ActionNames::Interaction))
		{
			if (GunnerComponent.GetGunnerState() == EFlyingCarGunnerState::Rifle)
				GunnerComponent.SetGunnerState(EFlyingCarGunnerState::Bazooka);
			else
				GunnerComponent.SetGunnerState(EFlyingCarGunnerState::Rifle);
		}

		USkylineFlyingCarPilotComponent PilotComponent = USkylineFlyingCarPilotComponent::Get(Player.OtherPlayer);
		if (PilotComponent != nullptr && PilotComponent.Car != nullptr)
		{
			if (WasActionStarted(ActionNames::MovementSprint))
				PilotComponent.bSteeringOverridenByGunner = !PilotComponent.bSteeringOverridenByGunner;

			if (PilotComponent.bSteeringOverridenByGunner)
			{
				PrintScaled("🤯 Gunner steering 🤯", 0, FLinearColor::Green, 3);

				float InvertValue = Player.IsSteeringPitchInverted() ? -1 : 1;
				FVector2D RawStick = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

				PilotComponent.Car.YawInput = RawStick.Y;
				PilotComponent.Car.PitchInput = RawStick.X * InvertValue;
				PilotComponent.Car.bWasJumpActionStarted = WasActionStarted(ActionNames::MovementJump);
			}
		}
#endif
	}

	UFUNCTION()
	private void OnCollision(FSkylineFlyingCarCollision Collision)
	{
		TSubclassOf<UCameraShakeBase> CameraShake = Collision.Type == ESkylineFlyingCarCollisionType::TotalLoss ?
			GunnerComponent.Car.FatalCollisionCameraShake :
			GunnerComponent.Car.LightCollisionCameraShake;

		Player.PlayCameraShake(CameraShake, this);
		Player.PlayForceFeedback(GunnerComponent.Car.ImpactForceFeedback, false, false, this, 1.0);
	}
}