class ACoastFloatingMesh : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent StaticMesh;

	FHazeAcceleratedVector AcceleratedLocation;

	bool bFloatingMeshActive = false;

	UPROPERTY(EditInstanceOnly)
	float Stiffness = 13;

	UPROPERTY(EditInstanceOnly)
	float Damping = 0.2;

	UPROPERTY(EditInstanceOnly)
	float RotationInterpSpeed = 1;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedLocation.SnapTo(ActorLocation);
	}

	UFUNCTION(BlueprintCallable)
	void StartFloatingMesh()
	{
		SetActorTickEnabled(true);
		Timer::SetTimer(this, n"RemoveFloatingMesh", 6);
	}

	UFUNCTION()
	private void RemoveFloatingMesh()
	{
		AddActorDisable(this);
		OceanWaves::RemoveWaveDataInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		OceanWaves::RequestWaveData(this, ActorLocation);
		FWaveData WaveData = OceanWaves::GetLatestWaveData(this);
		FVector TargetLocation = FVector(ActorLocation.X, ActorLocation.Y, WaveData.PointOnWave.Z);
		ActorLocation = AcceleratedLocation.SpringTo(TargetLocation, Stiffness, Damping, DeltaSeconds);

		FRotator TargetRotation = FRotator::MakeFromZX(WaveData.PointOnWaveNormal, ActorForwardVector);
		ActorRotation = Math::RInterpTo(ActorRotation, TargetRotation, DeltaSeconds, RotationInterpSpeed);
		
	}
};