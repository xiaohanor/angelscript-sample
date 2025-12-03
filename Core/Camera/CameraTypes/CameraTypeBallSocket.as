
/**
 * 
 */
UCLASS(NotBlueprintable)
class UBallSocketCamera : UHazeCameraComponent
{
	default CameraUpdaterType = UCameraBallSocketUpdater;
	default bWantsCameraInput = true;
	
	float BallSocketRotationSpeed = -1.0;
}

/**
 *
 */
UCLASS(NotBlueprintable)
class UCameraBallSocketUpdater : UHazeCameraUpdater
{
	float RotationSpeed = 0;
	private FHazeAcceleratedRotator WorldRotation;

	UFUNCTION(BlueprintOverride)
	void Copy(const UHazeCameraUpdater SourceBase)
	{
		auto Source = Cast<UCameraBallSocketUpdater>(SourceBase);
		WorldRotation = Source.WorldRotation;
		RotationSpeed = Source.RotationSpeed;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraSnap(FHazeCameraTransform& OutResult)
	{
		WorldRotation.SnapTo(OutResult.WorldDesiredRotation);
		FRotator NewRot = ClampWorldRotation(WorldRotation.Value);
		OutResult.ViewRotation = NewRot;
	}

	UFUNCTION(BlueprintOverride)
	void OnCameraUpdate(float DeltaSeconds, FHazeCameraTransform& OutResult)
	{
		FRotator DesiredRot = OutResult.WorldDesiredRotation;
		if(RotationSpeed > 0)
		{
			const float Duration = 360.0 / RotationSpeed;
			WorldRotation.AccelerateTo(DesiredRot, Duration, DeltaSeconds);
		}
		else
		{
			WorldRotation.SnapTo(DesiredRot);
		}

		FRotator NewRot = ClampWorldRotation(WorldRotation.Value);
		OutResult.ViewRotation = NewRot;
	}
}


/**
 * 
 */
#if EDITOR
class UBallSocketCameraVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UBallSocketCamera;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto Camera = Cast<UBallSocketCamera>(Component);
		Camera.VisualizeCameraEditorPreviewLocation(this);
	}
}

#endif