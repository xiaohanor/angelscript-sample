UCLASS(Abstract)
class AMagnetLaunchPrisonGuard : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent MeshOffsetComponent;

	UPROPERTY(DefaultComponent)
	UHazeCharacterSkeletalMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	URagdollComponent RagdollComp;

	UPROPERTY(EditDefaultsOnly)
	FHazePlaySlotAnimationParams LaunchedSlotAnimation;

	UFUNCTION(BlueprintCallable)
	void Launch(FVector Impulse)
	{
		RagdollComp.ApplyRagdoll(Mesh, nullptr);
		RagdollComp.ApplyRagdollImpulse(Mesh, FRagdollImpulse(ERagdollImpulseType::WorldSpace, Impulse, FVector::ZeroVector));

		Mesh.PlaySlotAnimation(LaunchedSlotAnimation);
	}
};