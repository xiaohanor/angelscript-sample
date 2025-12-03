class ASanctuaryBossSkydiveHydraDeathZone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USpotLightComponent HydraSpotLight;

	UPROPERTY(EditAnywhere)
	ASanctuary_Skydive_Hydra Hydra;

	//UPROPERTY(DefaultComponent)
	//UDeathVolumeComponent DeathVolume;

	UPROPERTY(DefaultComponent)
	USceneComponent AttachRoot;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HydraSpotLight.AttachTo(Hydra.Mesh, n"Head");
		//DeathVolume.AttachTo(Hydra.Mesh, n"Head");
		AttachRoot.AttachTo(Hydra.Mesh, n"Head");

		Hydra.OnActivated.AddUFunction(this, n"HandleActivated");

		AddActorDisable(this);
	}

	UFUNCTION()
	private void HandleActivated()
	{
		RemoveActorDisable(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

		FHazeFrameForceFeedback FF;
		FF.LeftMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));
		FF.RightMotor = Math::Abs(Math::PerlinNoise1D(Math::Max(0.1, Time::GameTimeSeconds * 150)));

		ForceFeedback::PlayWorldForceFeedbackForFrame(FF, AttachRoot.WorldLocation, 3000, 4000);
		
	}


};