class AWallowMudPuddle : AHazeActor
{
	default AddActorTag(PigTags::Wallow);

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;
}