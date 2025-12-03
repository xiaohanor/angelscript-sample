
class ACentipedeKeepInViewCameraActor : AFocusCameraActor 
{
	default FocusTargetComponent.EmptyTargetDefaultType = ECameraWeightedTargetEmptyInitType::DefaultToBothPlayers;
	default Camera.KeepInViewSettings.bUseMinDistance = true;
	default Camera.KeepInViewSettings.MinDistance = 1500;
	default Camera.KeepInViewSettings.bUseMaxDistance = true;
	default Camera.KeepInViewSettings.MaxDistance = 2000;
}


class UCentipedeCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CentipedeTags::Centipede);

	default TickGroup = EHazeTickGroup::LastDemotable;

	default DebugCategory = CentipedeTags::Centipede;

	UPlayerCentipedeComponent CentipedeComponent;
	ACentipedeKeepInViewCameraActor KeepInViewCamera;

	UCameraUserComponent CameraUserComponent;

	const float MinDistance = 1500;
	const float MaxDistance = 2000;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		CentipedeComponent = UPlayerCentipedeComponent::Get(Owner);
		CameraUserComponent = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Player.IsMio())
			return false;

		if (!CentipedeComponent.IsCentipedeActive())
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!CentipedeComponent.IsCentipedeActive())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Instant, EHazeViewPointPriority::Low);

		// Eman TODO: Hax
		// KeepInViewCamera = SpawnActor(ACentipedeKeepInViewCameraActor);
	
		// KeepInViewCamera.KeepInViewComponent.DefaultSettings.bUseLookOffset = true;
		// KeepInViewCamera.KeepInViewComponent.DefaultSettings.LookOffset = FRotator(-50, 45, 0);

		// Player.ActivateCamera(KeepInViewCamera, 1, this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Instant);
	}

	// UFUNCTION(BlueprintOverride)
	// void TickActive(float DeltaTime)
	// {
	// 	// Set camera rotation
	// 	FRotator TargetCameraRotation = GetCameraRotation();
	// 	FRotator CameraRotation = Math::RInterpShortestPathTo(KeepInViewCamera.ControlRotation, TargetCameraRotation, DeltaTime, 1.0);
	// 	KeepInViewCamera.SetActorRotation(CameraRotation);
	// }

	// FRotator GetCameraRotation()
	// {
	// 	FVector UpVector = (GetPlayerGroundNormal(Player) + GetPlayerGroundNormal(Player.OtherPlayer)).GetSafeNormal();
	// 	FRotator CameraRotation = FRotator::MakeFromX(-UpVector);
	// 	return CameraRotation;
	// }

	// FVector GetPlayerGroundNormal(AHazePlayerCharacter PlayerCharacter)
	// {
	// 	UPlayerCentipedeSwingComponent SwingComponent = UPlayerCentipedeSwingComponent::Get(PlayerCharacter);
	// 	if (SwingComponent != nullptr)
	// 	{
	// 		if (SwingComponent.GetActiveSwingPoint() != nullptr)
	// 			return SwingComponent.GetActiveSwingPoint().SwingPlaneVector;
	// 	}

	// 	return Player.MovementWorldUp;
	// }
}