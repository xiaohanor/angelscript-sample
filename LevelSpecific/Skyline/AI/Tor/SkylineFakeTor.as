class ASkylineFakeTor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	URagdollComponent RagdollComp;

	UPROPERTY(DefaultComponent, Attach = FakeTor)
	UHazeCapsuleCollisionComponent PlayerCollision;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase FakeTor;



	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ApplyRagdollFun();
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintCallable)
	void EnableFakeTorTick()
	{
		SetActorTickEnabled(true);
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(0, -1000, 500), FVector::ZeroVector, n"LeftForeArm"));
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(0, 1000, 500), FVector::ZeroVector, n"RightForeArm"));
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(-20000, 0, 2000), FVector::ZeroVector, n"Spine2"));
	}

	UFUNCTION(BlueprintCallable)
	void ApplyRagdollFun()
	{
		RagdollComp.ApplyRagdoll(FakeTor, PlayerCollision);
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(0, -1000, 500), FVector::ZeroVector, n"LeftForeArm"));
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(0, 1000, 500), FVector::ZeroVector, n"RightForeArm"));
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(-20000, 0, 2000), FVector::ZeroVector, n"Spine2"));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		RagdollComp.ApplyRagdollImpulse(FakeTor, FRagdollImpulse(ERagdollImpulseType::ActorSpace, FVector(FakeTor.GetForwardVector() * -200), FVector::ZeroVector, n"Spine2"));
	}
};