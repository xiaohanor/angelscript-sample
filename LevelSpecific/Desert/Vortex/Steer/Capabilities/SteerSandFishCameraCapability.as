struct FSteerSandFishCameraActivateParams
{
	bool bWasProgressPoint;
}

class USteerSandFishCameraCapability : UHazeCapability
{
	//default CapabilityTags.Add(ArenaSandFish::Tags::ArenaSandFishCamera);

	default TickGroup = EHazeTickGroup::LastDemotable;
	default TickGroupOrder = 100;

	AVortexSandFish SandFish;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		SandFish = Cast<AVortexSandFish>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSteerSandFishCameraActivateParams& Params) const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return false;

		Params.bWasProgressPoint = Desert::GetDesertLevelState() == Desert::GetDesertProgressPointLevelState();

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(Desert::GetDesertLevelState() != EDesertLevelState::Steer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSteerSandFishCameraActivateParams Params)
	{
		const float BlendTime = Params.bWasProgressPoint ? 0 : 2;
		const EHazeViewPointBlendSpeed BlendSpeed = Params.bWasProgressPoint ? EHazeViewPointBlendSpeed::Instant : EHazeViewPointBlendSpeed::Normal;

		Game::Mio.ActivateCamera(SandFish.SteerCamera, BlendTime, this, EHazeCameraPriority::VeryHigh);
		Game::Mio.ApplyViewSizeOverride(this, EHazeViewPointSize::Fullscreen, BlendSpeed);

		//Game::Mio.BlockCapabilities(ArenaSandFish::PlayerTags::ArenaSandFishPlayerCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Mio.ClearViewSizeOverride(this, EHazeViewPointBlendSpeed::Normal);
		Game::Mio.DeactivateCameraByInstigator(this, 2);

		//Game::Mio.UnblockCapabilities(ArenaSandFish::PlayerTags::ArenaSandFishPlayerCamera, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform SplineTransform = SandFish.SteerSpline.Spline.GetWorldTransformAtSplineDistance(SandFish.SteerDistanceAlongSpline);
		FVector FollowLocation = SplineTransform.Location;

		FVector Offset = FVector(-5000, 0, 2000);
		Offset = SplineTransform.TransformVectorNoScale(Offset);

		FVector CameraLocation = FollowLocation + Offset;

		FQuat CameraRotation = FQuat::MakeFromXZ(-Offset, FVector::UpVector);

		SandFish.SteerCamera.SetActorLocationAndRotation(CameraLocation, CameraRotation);
	}
};