event void FSanctuaryWeeperRuneSignature();

class ASanctuaryWeeperRune : AHazeActor
{
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperRuneSignature OnActivated;
	UPROPERTY(Meta = (NotBlueprintCallable))
	FSanctuaryWeeperRuneSignature OnDeactivated;


	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToChannel(ECollisionChannel::WorldGeometry, ECollisionResponse::ECR_Ignore);

	UPROPERTY(DefaultComponent)
	USanctuaryWeeperArtifactResponseComponent ArtifactResponseComp;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ArtifactResponseComp.OnIlluminated.AddUFunction(this, n"OnIlluminated");
		ArtifactResponseComp.OnStopIlluminated.AddUFunction(this, n"OnStopIlluminated");
	}



	UFUNCTION()
	private void OnIlluminated(ASanctuaryWeeperArtifact Artifact)
	{
		OnActivated.Broadcast();
	}

	UFUNCTION()
	private void OnStopIlluminated(ASanctuaryWeeperArtifact Artifact)
	{
		OnDeactivated.Broadcast();

	}

};