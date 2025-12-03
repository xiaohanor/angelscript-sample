class UBabaYagaSwingCameraCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default TickGroup = EHazeTickGroup::LastMovement;

	ABabaYagaSwingCamera Camera;
	AActor  TargetActor;

	FVector FocusPoint;
	float CameraDirectionOffset = 1000.0;

	FHazeAcceleratedVector AccelVec;
	FHazeAcceleratedRotator AccelRot;

	FVector WorldOffset = FVector(0,0,-100.0);

	float BlendTime = 4.5;
	float BlendDuration = 0.4;

	AHazePlayerCharacter Player;
	UPlayerSwingComponent SwingComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Camera = Cast<ABabaYagaSwingCamera>(Owner);
		FocusPoint = Camera.FocusPoint.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!Camera.bPlayerSwinging)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (!Camera.bPlayerSwinging)
			return true;

		if(!SwingComp.IsCurrentlySwinging())
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		Player = Camera.TargetPlayer;
		SwingComp = UPlayerSwingComponent::Get(Player);
		Camera.TargetPlayer.ActivateCamera(Camera, BlendTime, this, EHazeCameraPriority::VeryHigh);
		TargetActor = Camera.TargetFollowActor;
		FTransform CameraTargetTransform = GetCameraTransform();
		AccelVec.SnapTo(CameraTargetTransform.Location);
		AccelRot.SnapTo(CameraTargetTransform.Rotation.Rotator());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Player.DeactivateCamera(Camera, BlendOutTime = 1.0);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FTransform CameraTargetTransform = GetCameraTransform();
		AccelVec.AccelerateTo(CameraTargetTransform.Location, BlendDuration, DeltaTime);
		AccelRot.AccelerateTo(CameraTargetTransform.Rotation.Rotator(), BlendDuration, DeltaTime);

		Camera.SetActorLocationAndRotation(AccelVec.Value, AccelRot.Value);

		// Debug::DrawDebugSphere(Camera.ActorLocation, 200, 12, FLinearColor::Purple, 5.0);
		// Debug::DrawDebugSphere(CameraTargetTransform.Location, 100, 12, FLinearColor::Red, 5.0);
		// Debug::DrawDebugLine(Camera.ActorLocation, FocusPoint, FLinearColor::Green, 5.0);
		// Debug::DrawDebugSphere(FocusPoint, 200, 12, FLinearColor::Red, 5.0);
	}

	FTransform GetCameraTransform()
	{
		FVector Direction = (FocusPoint - TargetActor.ActorLocation).GetSafeNormal();
		FVector CamLoc = TargetActor.ActorLocation - Direction * CameraDirectionOffset;
		CamLoc += WorldOffset; 
		CamLoc += TargetActor.ActorForwardVector * 100.0;

		float HeightDifference = TargetActor.ActorLocation.Z - FocusPoint.Z;
		HeightDifference /= 3.0;
		
		FVector UpdatedFocusPoint = FocusPoint;
		UpdatedFocusPoint += FVector::UpVector * HeightDifference;

		PrintToScreen(f"{HeightDifference=}"); 
		FQuat CamQuat = FQuat::MakeFromXZ((UpdatedFocusPoint - TargetActor.ActorLocation).GetSafeNormal(), FVector::UpVector);

		FTransform NewTransform;
		NewTransform.Location = CamLoc;	
		NewTransform.Rotation = CamQuat;

		return NewTransform;	
	}
};