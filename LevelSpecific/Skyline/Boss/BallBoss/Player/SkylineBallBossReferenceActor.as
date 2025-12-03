class ASkylineBallBossReferenceActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	UPROPERTY(DefaultComponent)
	UHazeListedActorComponent ListedComp;
	UPROPERTY(EditAnywhere)
	ASkylineBallBoss BallBoss;

	UPROPERTY(EditAnywhere)
	AFocusCameraActor MioDeathCamera;
	UPROPERTY(EditAnywhere)
	AStaticCameraActor MioInsideDeathCamera;
	UPROPERTY(EditAnywhere)
	AFocusCameraActor ZoeDeathCamera;
	UPROPERTY(EditAnywhere)
	float DeathCameraBlendInTime = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		USkylineBallBossActorReferenceComponent TempMio = USkylineBallBossActorReferenceComponent::GetOrCreate(Game::Mio);
		TempMio.Refs = this;
		USkylineBallBossActorReferenceComponent TempZoe = USkylineBallBossActorReferenceComponent::GetOrCreate(Game::Zoe);
		TempZoe.Refs = this;
	}
};