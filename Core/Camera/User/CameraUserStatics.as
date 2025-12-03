mixin AHazePlayerCharacter GetPlayerOwner(const UHazeCameraUserComponent User)
{
	return Cast<AHazePlayerCharacter>(User.Owner);
}

mixin bool IsUsingGamepad(const UHazeCameraUserComponent User)
{
	AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.Owner);
	if (PlayerUser == nullptr)
		return false;
	return PlayerUser.IsUsingGamepad();
}

mixin FVector GetOwnerRawLastFrameTranslationVelocity(const UHazeCameraUserComponent User)
{
	AHazeActor HazeOwner = Cast<AHazeActor>(User.Owner);
	if (HazeOwner == nullptr)
		return User.Owner.GetActorVelocity();
	return HazeOwner.GetRawLastFrameTranslationVelocity();
}

mixin bool IsSelectedBy(const UHazeCameraUserComponent User, EHazeSelectPlayer SelectPlayer)
{
	AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.Owner);
	if (PlayerUser == nullptr)
		return false;
	return PlayerUser.IsSelectedBy(SelectPlayer);
}

mixin bool HasFullScreen(const UHazeCameraUserComponent User)
{
	return SceneView::IsFullScreen() && (SceneView::FullScreenPlayer == User.Owner);
}

mixin bool HasNoScreen(const UHazeCameraUserComponent User)
{
	return SceneView::IsFullScreen() && (SceneView::FullScreenPlayer != User.Owner);
}

mixin UHazeCameraUserComponent GetOtherUser(const UHazeCameraUserComponent User)
{
	AHazePlayerCharacter OtherPlayer = User.GetOtherPlayer();
	if (OtherPlayer == nullptr)
		return nullptr;
	return UHazeCameraUserComponent::Get(OtherPlayer);
}

mixin AHazePlayerCharacter GetOtherPlayer(const UHazeCameraUserComponent User)
{
	AHazePlayerCharacter PlayerUser = Cast<AHazePlayerCharacter>(User.Owner);
	if (PlayerUser == nullptr)
		return nullptr;
	return PlayerUser.OtherPlayer;
}