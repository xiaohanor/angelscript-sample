class ASkylineBossFlyingPhaseActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;

	USkylineBossFlyingPhaseHealthComp HealthComp;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = Body)
	USphereComponent CoreCollision;
	default CoreCollision.bGenerateOverlapEvents = false;

	UPROPERTY()
	UHazeCapabilitySheet CapabilitySheet;

	TInstigated<AActor> MoveToTarget;
	TInstigated<AHazeActor> LookAtTarget;

	
	AGravityBikeFree GetBikeFromTarget(AHazeActor Target)
	{
		auto DriverComp = UGravityBikeFreeDriverComponent::Get(Target);
		if (DriverComp != nullptr)
		{
			return DriverComp.GetGravityBike();
		}

		return nullptr;
	}

	UFUNCTION()
	void SetLookAtTarget(AHazeActor Target)
	{
		AHazeActor BikeTarget = GetBikeFromTarget(Target);

		LookAtTarget.Empty();
		LookAtTarget.Apply(BikeTarget, this);
	}

	UFUNCTION(BlueprintCallable)
	void ActivateFlyingPhase()
	{
		StartCapabilitySheet(CapabilitySheet, this);
	}
};