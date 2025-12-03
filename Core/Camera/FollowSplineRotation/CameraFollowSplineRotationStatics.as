UFUNCTION(BlueprintCallable)
mixin void ApplyCameraFollowSplineRotation(AHazePlayerCharacter Player, UHazeSplineComponent Spline, FInstigator Instigator, FCameraFollowSplineRotationSettings Settings, float BlendDuration = 1, EInstigatePriority Priority = EInstigatePriority::Low)
{
	auto CameraFollowSplineRotationComp = UCameraFollowSplineRotationComponent::GetOrCreate(Player);
	FCameraFollowSplineRotationData Data(Spline, Settings);
	CameraFollowSplineRotationComp.Apply(Data, Instigator, BlendDuration, Priority);
}

UFUNCTION(BlueprintCallable)
mixin void ClearCameraFollowSplineRotation(AHazePlayerCharacter Player, FInstigator Instigator, float BlendDuration = -1)
{
	auto CameraFollowSplineRotationComp = UCameraFollowSplineRotationComponent::GetOrCreate(Player);
	CameraFollowSplineRotationComp.Clear(Instigator, BlendDuration);
}

UFUNCTION(BlueprintCallable)
mixin void BlockCameraFollowSplineRotation(AHazePlayerCharacter Player, FInstigator Instigator, float BlendDuration = -1)
{
	auto CameraFollowSplineRotationComp = UCameraFollowSplineRotationComponent::GetOrCreate(Player);
	CameraFollowSplineRotationComp.Block(Instigator, BlendDuration);
}

UFUNCTION(BlueprintCallable)
mixin void UnblockCameraFollowSplineRotation(AHazePlayerCharacter Player, FInstigator Instigator, float BlendDuration = 1)
{
	auto CameraFollowSplineRotationComp = UCameraFollowSplineRotationComponent::GetOrCreate(Player);
	CameraFollowSplineRotationComp.Unblock(Instigator, BlendDuration);
}