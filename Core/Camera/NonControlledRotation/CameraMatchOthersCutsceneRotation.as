// Capability to match desired rotation of other players view rotation when other player is 
// controlled by cutscene and had full screen.
// Useful if you want to blend in split screen before cutscene is over and have both players 
// view behave as if cutscene controlled.
class UCameraMatchOthersCutsceneRotationCapability : UHazeCapability
{
	UCameraUserComponent User;
	AHazePlayerCharacter PlayerUser;
	AHazePlayerCharacter OtherPlayer;
	UCameraSettings CameraSettings;

	default CapabilityTags.Add(CameraTags::Camera);
	default CapabilityTags.Add(n"PlayerDefault");
	default CapabilityTags.Add(CameraTags::CameraNonControlled);
	default CapabilityTags.Add(n"CameraMatchOthersCutsceneRotation");

	// This should overwrite anything we get from input
	default TickGroup = EHazeTickGroup::BeforeGameplay;
    default DebugCategory = CameraTags::Camera;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		User = UCameraUserComponent::Get(Owner);
		PlayerUser = Cast<AHazePlayerCharacter>(Owner);
		CameraSettings = UCameraSettings::GetSettings(PlayerUser);
		OtherPlayer = PlayerUser.OtherPlayer;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (OtherPlayer.ActiveLevelSequenceActor == nullptr)
			return false;
		if (!OtherPlayer.ActiveLevelSequenceActor.bOtherPlayerMatchCameraRotation)
		 	return false;

		// We only only want this to apply when other player _exits_ from 
		// full screen, not at start of cutscenes.
		if (!SceneView::IsFullScreen() || (SceneView::GetFullScreenPlayer() != OtherPlayer))
		 	return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (OtherPlayer.ActiveLevelSequenceActor == nullptr)
			return true;
		if (!OtherPlayer.ActiveLevelSequenceActor.bOtherPlayerMatchCameraRotation)
		 	return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		// Sensitivity should blend in after thís deactivates
		CameraSettings.SensitivityFactor.Apply(0, this, 2, EHazeCameraPriority::Low);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		// Initially slow sensitivity after this has been active
		PlayerUser.ClearCameraSettingsByInstigator(this, 2.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Set desired rotation to othre players current view rotation
		FRotator ViewRot = PlayerUser.OtherPlayer.ViewRotation;
		FRotator ViewRotLocal = User.WorldToLocalRotation(ViewRot);
		FRotator CurRotLocal = User.WorldToLocalRotation(User.GetDesiredRotation());
		User.AddDesiredRotation(ViewRotLocal - CurRotLocal, this);
	}
}
