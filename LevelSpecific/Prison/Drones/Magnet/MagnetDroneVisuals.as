/**
 * Visual actor for Magnet Drone.
 * Will be attached to MeshOffsetComponent on the player in UMagnetDroneComponent::CreateDroneMeshComponent.
 */
UCLASS(Abstract)
class AMagnetDroneVisuals : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UPoseableMeshComponent MeshComp;
	default MeshComp.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = MeshComp)
	UPointLightComponent PointLight;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif
};