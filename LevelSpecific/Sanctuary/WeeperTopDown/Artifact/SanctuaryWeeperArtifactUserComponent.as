class USanctuaryWeeperArtifactUserComponent : UActorComponent
{

	TArray<USanctuaryWeeperArtifactResponseComponent> ArtifactResponseComps;
	ASanctuaryWeeperArtifact Artifact;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		
	}
};