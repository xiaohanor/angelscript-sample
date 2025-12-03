
class ASanctuaryCompanionAviationPostAttackCamera : ASplineFollowCameraActor
{
#if EDITOR
	default CameraSpline.EditingSettings.SplineColor = FLinearColor::LucBlue;
	default CameraSpline.EditingSettings.bEnableVisualizeScale = true;
	default CameraSpline.EditingSettings.VisualizeScale = 1;
#endif 

	UPROPERTY(EditAnywhere)
	EHazeSelectPlayer Player;

	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComponent;
};