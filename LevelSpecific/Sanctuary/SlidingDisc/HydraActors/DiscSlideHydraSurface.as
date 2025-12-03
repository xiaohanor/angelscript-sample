// simple geometric version for building the spline and raytracing collision :)
UCLASS(Abstract)
class ADiscSlideHydraSurface : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase SkeletalMesh;
	default SkeletalMesh.bVisible = false;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"DiscSlideHydraBuildGrindSplineCapability");

	UPROPERTY(DefaultComponent)
    UHazeMeshPoseDebugComponent MeshPoseDebugComponent;

	TArray<FName> BoneNames;
	FHazeRuntimeSpline RuntimeSpline;
	bool bHasSpline = false;

	bool bPlayersAreGrinding = false;

	float GrindRadius = 1900.0;

	UFUNCTION(BlueprintPure)
	UHazeSkeletalMeshComponentBase SkellyMesh() const
	{
		return SkeletalMesh;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (BoneNames.IsEmpty())
		{
			for (int i = 1; i < 50; ++i)
			{
				FString StringBone = "Spine" + i;
				FName BoneName = FName(StringBone);
				BoneNames.Add(BoneName);
			}
		}
	}
}