UCLASS(Abstract)
class AJetSkiEscapeAnimActor : AOctopusTentacleSequenceActor
{
	UPROPERTY(DefaultComponent, EditAnywhere, Attach = Skelmesh, AttachSocket = "Base")
	UStaticMeshComponent StaticMesh;
};
