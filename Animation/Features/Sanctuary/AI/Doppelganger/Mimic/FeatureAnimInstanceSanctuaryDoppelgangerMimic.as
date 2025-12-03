UCLASS(Abstract)
class UFeatureAnimInstanceSanctuaryDoppelgangerMimic : UFeatureAnimInstanceAIBase
{
	USanctuaryDoppelgangerComponent DoppelComp;

	UPROPERTY(BlueprintReadOnly)
	FHazeMeshPose MimicPose;

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Super::BlueprintInitializeAnimation();
		if (HazeOwningActor == nullptr)
			return; // Editor preview
		DoppelComp = USanctuaryDoppelgangerComponent::Get(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
    {
        Super::BlueprintUpdateAnimation(DeltaTime);

		if (DoppelComp == nullptr)
			return; // Editor preview

		if (DoppelComp.MimicTarget != nullptr)
			MimicPose.CopyPoseFromMesh(DoppelComp.MimicTarget.Mesh);
	}
}
