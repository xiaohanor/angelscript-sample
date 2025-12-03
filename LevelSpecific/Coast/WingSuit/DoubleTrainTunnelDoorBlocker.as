class ADoubleTrainTunnelDoorBlocker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsAxisRotateComponent FauxPhysicsRotationRoot;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsRotationRoot)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = FauxPhysicsRotationRoot)
	UFauxPhysicsWeightComponent FauxPhysicsWeight;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent Mesh;

	FHazeAcceleratedFloat ForceToApply;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForceToApply.SnapTo(0);
		FauxPhysicsWeight.AddDisabler(this);
		ActorTickEnabled = false;
		FauxPhysicsRotationRoot.OnMinConstraintHit.AddUFunction(this, n"StopRotationForce");
	}

	UFUNCTION()
	private void StopRotationForce(float Strength)
	{
		ActorTickEnabled = false;
	}

	UFUNCTION(BlueprintCallable)
	void DoorWasHit()
	{
		Timer::SetTimer(this, n"StartActorTick", 0.5);
	}

	UFUNCTION()
	void StartActorTick()
	{
		ActorTickEnabled = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		ForceToApply.AccelerateTo(12, 4, DeltaSeconds);
		FauxPhysicsRotationRoot.ApplyAngularForce(ForceToApply.Value);
		PrintToScreen("TICKERSSS", 0);
	}
};