class UCoastWaterskiCameraCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(n"Waterski");
	default CapabilityTags.Add(CapabilityTags::Camera);
	default CapabilityTags.Add(n"WaterskiCamera");

	default TickGroup = EHazeTickGroup::AfterGameplay;

	UCoastWaterskiPlayerComponent WaterskiComp;
	UCameraUserComponent CameraUser;
	UPlayerAimingComponent AimComponent;
	FTransform PreviousTransform;
	UHazeSplineComponent TrainSpline;
	UCoastWaterskiSettings Settings;
	UCameraSettings CameraSettings;
	int SplineDirection = 1;
	FHazeAcceleratedVector2D AcceleratedCameraInput;
	float CurrentAccelerationDuration;
	FRotator OriginalRotation;
	FHazeAcceleratedFloat AcceleratedPivotOffset;
	UHazeCrumbSyncedRotatorComponent SyncedWaterskiCameraRotation;
	UHazeCrumbSyncedVectorComponent SyncedWorldPivotOffset;

	const float BlendTime = 0.5;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		WaterskiComp = UCoastWaterskiPlayerComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		AimComponent = UPlayerAimingComponent::Get(Player);
		Settings = UCoastWaterskiSettings::GetSettings(Player);
		CameraSettings = UCameraSettings::GetSettings(Player);

		SyncedWaterskiCameraRotation = UHazeCrumbSyncedRotatorComponent::GetOrCreate(Player, n"SyncedWaterskiCameraRotation");
		SyncedWaterskiCameraRotation.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
		SyncedWorldPivotOffset = UHazeCrumbSyncedVectorComponent::GetOrCreate(Player, n"SyncedWaterskiWorldPivotOffset");
		SyncedWorldPivotOffset.OverrideSyncRate(EHazeCrumbSyncRate::PlayerSynced);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return false;

		if(AimComponent.IsAiming())
			return false;

		if (WaterskiComp.WaterLandscape == nullptr)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!WaterskiComp.IsWaterskiing())
			return true;

		if(AimComponent.IsAiming())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player.BlockCapabilities(CameraTags::CameraControl, this);
		PreviousTransform = WaterskiAttachPoint.WorldTransform;

		auto BackmostCart = Cast<ACoastTrainCart>(WaterskiAttachPoint.AttachmentRoot.Owner);
		TrainSpline = BackmostCart.RailSpline;
		SplineDirection = BackmostCart.Driver.bReverseOnRail ? -1 : 1;

		OriginalRotation = CameraUser.GetDesiredRotation();
		FVector OriginalPivotLag = CameraSettings.PivotLagMaxMultiplier.Value;
		CameraSettings.PivotLagMaxMultiplier.Apply(FVector(OriginalPivotLag.X, OriginalPivotLag.Y, 0.2), WaterskiComp);

		AcceleratedPivotOffset.SnapTo(0.0);

		SyncedWaterskiCameraRotation.Value = OriginalRotation;
		SyncedWaterskiCameraRotation.SnapRemote();

		SyncedWorldPivotOffset.Value = FVector::ZeroVector;
		SyncedWorldPivotOffset.SnapRemote();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.UnblockCapabilities(CameraTags::CameraControl, this);
		AcceleratedCameraInput.SnapTo(FVector2D::ZeroVector, FVector2D::ZeroVector);
		CameraSettings.WorldPivotOffset.Clear(WaterskiComp, 1.0);
		CameraSettings.PivotLagMaxMultiplier.Clear(WaterskiComp, 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			FVector OriginalPivotLag = CameraSettings.PivotLagMaxMultiplier.Value;
			CameraSettings.PivotLagMaxMultiplier.Apply(FVector(OriginalPivotLag.X, OriginalPivotLag.Y, 0.0), WaterskiComp);
			SetCameraRotation(DeltaTime);
			AddAttachPointDeltaRotation();
			OffsetCameraAboveLandscape(DeltaTime);
			SyncedWaterskiCameraRotation.Value = CameraUser.GetDesiredRotation();
		}
		else
		{
			CameraUser.SetDesiredRotation(SyncedWaterskiCameraRotation.Value, this);
			CameraSettings.WorldPivotOffset.ApplyAsAdditive(SyncedWorldPivotOffset.Value, WaterskiComp);
		}

		PreviousTransform = WaterskiAttachPoint.WorldTransform;
	}

	void SetCameraRotation(float DeltaTime)
	{
		const float AttachPointSplineDistance = TrainSpline.GetClosestSplineDistanceToWorldLocation(WaterskiAttachPoint.WorldLocation);
		float PointOfInterestDistance = AttachPointSplineDistance + (Settings.PointOfInterestSplineDistanceOffset * SplineDirection);

		if(TrainSpline.IsClosedLoop() && PointOfInterestDistance >= TrainSpline.SplineLength)
			PointOfInterestDistance = Math::Fmod(PointOfInterestDistance, TrainSpline.SplineLength);

		const FVector PointOfInterestBaseLocation = TrainSpline.GetWorldLocationAtSplineDistance(PointOfInterestDistance) + Settings.PointOfInterestWorldOffset;
		const FRotator BaseRotation = FRotator::MakeFromXZ((PointOfInterestBaseLocation - Player.ActorLocation).GetSafeNormal(), FVector::UpVector);

		const FVector2D CameraInput = GetAttributeVector2D(AttributeVectorNames::CameraDirection);

		float AccelerationDuration = GetPointOfInterestAccelerationDuration(CameraInput, DeltaTime);
		AcceleratedCameraInput.AccelerateTo(CameraInput, AccelerationDuration, DeltaTime);

		FRotator FinalRotation = BaseRotation + FRotator(
			AcceleratedCameraInput.Value.Y * Settings.PointOfInterestMaxTurnOffsetInDegrees, 
			AcceleratedCameraInput.Value.X * Settings.PointOfInterestMaxTurnOffsetInDegrees, 
			0.0
			);

		float Alpha = Math::Saturate(ActiveDuration / BlendTime);
		Alpha = Math::EaseInOut(0.0, 1.0, Alpha, 2.0);

		CameraUser.SetDesiredRotation(FQuat::Slerp(OriginalRotation.Quaternion(), FinalRotation.Quaternion(), Alpha).Rotator(), this);
	}

	const float AccelerationOutDuration = 1.0;
	const float AccelerationInDuration = 2.0;

	float GetPointOfInterestAccelerationDuration(FVector2D CameraInput, float DeltaTime)
	{
		float TargetAccelerationDuration = CameraInput.Size() > 0.9 ? AccelerationOutDuration : AccelerationInDuration;
		return TargetAccelerationDuration;
	}

	// This function will add the rotation of the attach point to the camera, (so if you look at the train you will look at the same spot even when going around bends etc.)
	void AddAttachPointDeltaRotation()
	{
		FRotator DeltaRotation = PreviousTransform.InverseTransformRotation(WaterskiAttachPoint.WorldRotation);
		DeltaRotation.Pitch = 0.0;
		CameraUser.AddDesiredRotation(DeltaRotation, this);
	}

	// This function will make sure that the camera can never focus on a point below the landscape (leads to camera hitting collision and looks weird to be that far underwater)
	void OffsetCameraAboveLandscape(float DeltaTime)
	{
		FVector Point = WaterskiComp.WaveData.PointOnWave;
		if(Math::IsNearlyEqual(Point.Z, -MAX_flt))
		{
			CameraSettings.WorldPivotOffset.ApplyAsAdditive(FVector::ZeroVector, WaterskiComp);
			SyncedWorldPivotOffset.Value = FVector::ZeroVector;
			return;
		}

		float CurrentOffset = Math::Max(Point.Z - Player.ActorLocation.Z, 0.0);
		// Likely the Wave Data hasn't loaded in yet // Fredrik
		if(CurrentOffset > 10000)
			CurrentOffset = 0.0;
		if(CurrentOffset > AcceleratedPivotOffset.Value)
		{
			AcceleratedPivotOffset.AccelerateTo(CurrentOffset, 0.3, DeltaTime);
		}
		else
		{
			AcceleratedPivotOffset.AccelerateTo(CurrentOffset, 1.0, DeltaTime);
		}

		FVector Value = FVector::UpVector * AcceleratedPivotOffset.Value;
		CameraSettings.WorldPivotOffset.ApplyAsAdditive(Value, WaterskiComp);
		SyncedWorldPivotOffset.Value = Value;
	}

	USceneComponent GetWaterskiAttachPoint() const property
	{
		return WaterskiComp.CurrentWaterskiAttachPoint;
	}
}