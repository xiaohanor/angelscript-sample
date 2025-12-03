class UDroneButtonMashInteractionCapability : UHazeCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default CapabilityTags.Add(n"DroneButtonMashInteraction");
	
	default TickGroup = EHazeTickGroup::Gameplay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UDroneComponent DroneComp;
	UDroneButtonMashInteractionPlayerComponent PlayerComp;
	ADroneButtonMashInteractionActor InteractionActor;

	float MaxRotationSpeed = 600.0;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UDroneButtonMashInteractionPlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (PlayerComp.CurrentInteractionActor == nullptr)
			return false;

		if (PlayerComp.CurrentInteractionActor.bInteractionCompleted)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (PlayerComp.CurrentInteractionActor == nullptr)
			return true;

		if (InteractionActor.bInteractionCompleted)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		DroneComp = UDroneComponent::Get(Player);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);
		Player.BlockCapabilities(MagnetDroneTags::MagnetDroneAim, this);
		Player.BlockCapabilities(DroneCommonTags::DroneDashCapability, this);

		Player.SetActorVelocity(FVector::ZeroVector);

		InteractionActor = PlayerComp.CurrentInteractionActor;

		FButtonMashSettings MashSettings;
		MashSettings.Mode = EButtonMashMode::ButtonMash;
		MashSettings.Duration = InteractionActor.MashSettings.Duration;
		MashSettings.Difficulty = InteractionActor.MashSettings.Difficulty;
		MashSettings.bAllowPlayerCancel = false;
		MashSettings.bBlockOtherGameplay = true;
		MashSettings.bShowButtonMashWidget = true;
		MashSettings.WidgetAttachComponent = InteractionActor.WidgetAttachComp;

		FOnButtonMashCompleted OnCompleted;
		OnCompleted.BindUFunction(this, n"ButtonMashCompleted");
		Player.StartButtonMash(MashSettings, this, OnCompleted);

		if (!InteractionActor.MashSettings.bCanBeCompleted)
			Player.SetButtonMashAllowCompletion(this, false);

		Player.SmoothTeleportActor(InteractionActor.DroneAttachComp.WorldLocation, InteractionActor.ActorRotation, this);
		DroneComp.GetDroneMeshComponent().SetWorldRotation(InteractionActor.ActorRotation);

		if (InteractionActor.CameraSettings != nullptr)
			Player.ApplyCameraSettings(InteractionActor.CameraSettings, 2.0, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(SwarmDroneTags::SwarmTransitionCapability, this);
		Player.UnblockCapabilities(MagnetDroneTags::MagnetDroneAim, this);
		Player.UnblockCapabilities(DroneCommonTags::DroneDashCapability, this);

		Player.StopButtonMash(this);

		Player.AddMovementImpulse(InteractionActor.ActorForwardVector * 1000.0 + (FVector::UpVector * 200.0));

		Player.ClearCameraSettingsByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float Progress = Player.GetButtonMashProgress(this);
		InteractionActor.CurrentProgress = Progress;

		DroneComp.GetDroneMeshComponent().AddLocalRotation(FRotator(Progress * MaxRotationSpeed * DeltaTime, 0.0, 0.0));

		if (InteractionActor.LinkedInteractionActor != nullptr)
		{
			if (InteractionActor.CurrentProgress >= 1.0 && InteractionActor.LinkedInteractionActor.CurrentProgress >= 1.0)
			{
				CrumbInteractionCompleted();
			}
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbInteractionCompleted()
	{
		InteractionActor.InteractionCompleted(Player);
		InteractionActor.LinkedInteractionActor.InteractionCompleted(Player.OtherPlayer);
	}

	UFUNCTION()
	private void ButtonMashCompleted()
	{
		InteractionActor.InteractionCompleted(Player);
	}
}