UCLASS()
class ASandSharkChaseIgnoreZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UHazeMovablePlayerTriggerComponent TriggerComp;
	default TriggerComp.Shape.Type = EHazeShapeType::Sphere;
	default TriggerComp.Shape.SphereRadius = 500;
	default TriggerComp.EditorLineThickness = 10;
};