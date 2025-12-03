class AGameShowArenaPlayerSpotLight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent SpotLightHazeSphere;

	UPROPERTY(DefaultComponent, Attach = Root)
	USpotLightComponent SpotLightComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	ULensFlareComponent LensFlareComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UGodrayComponent GodrayComp;

	UPROPERTY(EditAnywhere)
	EHazePlayer PlayerToLookAt;

	AHazePlayerCharacter PlayerTarget;
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerTarget = Game::GetPlayer(PlayerToLookAt);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ActorRotation = FRotator::MakeFromXZ(PlayerTarget.ActorLocation - ActorLocation, FVector::UpVector);
	}
};