enum EMagnetAnnoyingDroneState
{
	Idle,
	Grab,
	WaitForDrop,
	Drop,
};

asset MagnetAnnoyingDroneSheet of UHazeCapabilitySheet
{
	Capabilities.Add(UMagnetAnnoyingDroneIdleCapability);
	Capabilities.Add(UMagnetAnnoyingDroneGrabCapability);
	Capabilities.Add(UMagnetAnnoyingDroneWaitForDropCapability);
	Capabilities.Add(UMagnetAnnoyingDroneDropCapability);
};

UCLASS(Abstract)
class AMagnetAnnoyingDrone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UPoseableMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSocketComponent MagneticSocketComp;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultSheets.Add(MagnetAnnoyingDroneSheet);

	UPROPERTY(EditInstanceOnly)
	ASplineActor SplineToMoveAlong;

	UPROPERTY(EditAnywhere)
	UHazeCameraSettingsDataAsset CameraSettings;

	EMagnetAnnoyingDroneState State = EMagnetAnnoyingDroneState::Idle;
	FSplinePosition SplinePosition;
	AHazePlayerCharacter AttachedPlayer;
	float GrabAlpha = 0;
	FRotator InitialRightRotation;
	FRotator InitialLeftRotation;

	FHazeAcceleratedVector AccLocation;
	FHazeAcceleratedQuat AccRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagneticSocketComp.OnMagnetDroneAttached.AddUFunction(this, n"OnAttached");
		MagneticSocketComp.OnMagnetDroneDetached.AddUFunction(this, n"OnDetached");
		
		InitialRightRotation = MeshComp.GetBoneRotationByName(n"RightForeArm", EBoneSpaces::ComponentSpace);
		InitialLeftRotation = MeshComp.GetBoneRotationByName(n"LeftForeArm", EBoneSpaces::ComponentSpace);

		SplinePosition = SplineToMoveAlong.Spline.GetClosestSplinePositionToWorldLocation(ActorLocation);
		if(SplinePosition.IsForwardOnSpline())
			SplinePosition.ReverseFacing();

		ApplySplinePosition(-1);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Angle = Math::Lerp(0, 65, GrabAlpha);

		MeshComp.SetBoneRotationByName(n"RightForeArm", InitialRightRotation + FRotator(0, -Angle, 0), EBoneSpaces::ComponentSpace);
		MeshComp.SetBoneRotationByName(n"LeftForeArm", InitialLeftRotation + FRotator(0, Angle, 0), EBoneSpaces::ComponentSpace);
	}

	UFUNCTION()
	private void OnAttached(FOnMagnetDroneAttachedParams Params)
	{
		AttachedPlayer = Params.Player;

		AccLocation.Velocity = AttachedPlayer.ActorVelocity * 0.2;

		if(CameraSettings != nullptr)
		{
			AttachedPlayer.ApplyCameraSettings(CameraSettings, 2, this, EHazeCameraPriority::High);
		}
	}

	UFUNCTION()
	private void OnDetached(FOnMagnetDroneDetachedParams Params)
	{
		AttachedPlayer.ClearCameraSettingsByInstigator(this);
		AttachedPlayer = nullptr;
	}

	void ApplySplinePosition(float DeltaTime)
	{
		FVector TargetLocation = SplinePosition.WorldLocation;
		FQuat TargetRotation = FQuat::MakeFromZX(FVector::UpVector, SplinePosition.WorldForwardVector);

		if(DeltaTime < KINDA_SMALL_NUMBER)
		{
			SetActorLocationAndRotation(TargetLocation, TargetRotation);
			AccLocation.SnapTo(TargetLocation);
			AccRotation.SnapTo(TargetRotation);
			return;
		}

		AccLocation.SpringTo(TargetLocation, 20, 0.4, DeltaTime);
		AccRotation.SpringTo(TargetRotation, 3, 0.5, DeltaTime);

		SetActorLocationAndRotation(AccLocation.Value, AccRotation.Value);
	}
};