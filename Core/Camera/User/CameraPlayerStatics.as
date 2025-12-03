/**
 * Set the cameras wanted rotation this frame.
 * Some camera parent components (Like the spring arm) uses this value to rotate towards
 */
mixin FRotator GetCameraDesiredRotation(AHazePlayerCharacter Player)
{	
	return UCameraUserComponent::Get(Player).GetDesiredRotation();
}

/** Returns the diff from what you wanted it to be. 
	* It can diff if you try to set the desired rotation outside what clamps allows it to be.
	*/
mixin void SetCameraDesiredRotation(AHazePlayerCharacter Player, FRotator DesiredRotation, FInstigator Instigator)
{
	UCameraUserComponent CamUser = UCameraUserComponent::Get(Player);
	if (CamUser == nullptr)
		return;
	
	CamUser.SetDesiredRotation(DesiredRotation, Instigator);
}


UFUNCTION()
mixin void SnapCameraBehindPlayer(AHazePlayerCharacter Player)
{
	// This is valid, can happen from animation viewer for example
	if (Player == nullptr)
		return;

	UCameraUserComponent CamUser = UCameraUserComponent::Get(Player);
	if (CamUser == nullptr)
		return;
	
	CamUser.SnapCamera();
}

UFUNCTION()
mixin void SnapCameraBehindPlayerWithCustomOffset(AHazePlayerCharacter Player, FRotator Offset)
{
	// This is valid, can happen from animation viewer for example
	if (Player == nullptr)
		return;

	UCameraUserComponent CamUser = UCameraUserComponent::Get(Player);
	if (CamUser == nullptr)
		return;
	
	FQuat Rot = (FQuat(Player.GetActorRotation()) * FQuat(Offset));
	CamUser.SnapCamera(Rot.Vector());
}

mixin void SnapCameraAtEndOfFrame(AHazePlayerCharacter Player, FRotator Rotation /*= FRotator(-15.f, 0.f, 0.f)*/, EHazeCameraSnapType SnapType /*= EDeferredCameraSnapType::BehindUser*/)
{
	// This is valid, can happen from animation viewer for example
	if (Player == nullptr)
		return;

	UCameraUserComponent CamUser = UCameraUserComponent::Get(Player);
	if (CamUser == nullptr)
		return;

	CamUser.SnapCameraAtEndOfFrame(Rotation.Vector(), SnapType);
}
