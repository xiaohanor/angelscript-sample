UCLASS(Abstract)
class AIceLakeRaft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UStaticMeshComponent RaftMesh;

	UPROPERTY(DefaultComponent, Attach = "RaftMesh")
	UStaticMeshComponent MastsMesh;

	UPROPERTY(DefaultComponent, Attach = "MastsMesh")
	UStaticMeshComponent SailsMesh;

	UPROPERTY(DefaultComponent)
	UWindDirectionResponseComponent WindDirectionResponseComp;

	UPROPERTY(DefaultComponent, ShowOnActor)
	UIceLakeRaftComponent RaftComponent;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float Acceleration = 2.0;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float Drag = 1.0;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float RaftTurnAcceleration = 0.1;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float SailTurnStiffness = 20.0;

	UPROPERTY(EditAnywhere, Category = "Ice Lake Raft")
	float SailTurnDamping = 0.4;

	FVector Velocity;
	FRotator TargetRotation;
	FHazeAcceleratedRotator AccRaftRotation;
	FHazeAcceleratedRotator AccSailRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WindDirectionResponseComp.OnWindDirectionChanged.AddUFunction(this, n"OnWindDirectionChanged");
		TargetRotation = ActorRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float IntegratedDragFactor = Math::Exp(-Drag);
		Velocity = Velocity * Math::Pow(IntegratedDragFactor, DeltaSeconds);

		FVector Delta = Velocity * DeltaSeconds;
		AddActorWorldOffset(Delta);

		if(Velocity.SizeSquared() > KINDA_SMALL_NUMBER)
			TargetRotation = FRotator::MakeFromX(Velocity);

		AccRaftRotation.AccelerateTo(TargetRotation, 1.0 / RaftTurnAcceleration, DeltaSeconds);
		AccSailRotation.SpringTo(TargetRotation, SailTurnStiffness, SailTurnDamping, DeltaSeconds);

		SetActorRotation(AccRaftRotation.Value);
		SailsMesh.SetWorldRotation(AccSailRotation.Value);
	}

	UFUNCTION()
	void OnWindDirectionChanged(FVector WindDirection, FVector Location)
	{
		const float Distance = ActorLocation.Distance(Location);
		const float Factor = 1.0 - Math::Saturate(Math::NormalizeToRange(Distance, RaftComponent.MinAffectDistance, RaftComponent.MaxAffectDistance));
		Velocity += WindDirection * (Factor * Acceleration);
	}
};