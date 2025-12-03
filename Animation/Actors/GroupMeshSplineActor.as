
struct FHazeGroupMeshPerBaseBoneData
{
	FHazeGroupMeshPerBaseBoneData(FName InBoneName)
	{
		BoneName = InBoneName;
	}

	UPROPERTY(EditAnywhere)
	ASplineActor SplineActor;

	// Speed of movement along spline
	UPROPERTY(EditAnywhere)
	float Speed = 0.0;

	// Start offset time in seconds
	UPROPERTY(EditAnywhere)
	float StartOffset = 0.0;

	// If True, will hide this character when it is not following a spline
	UPROPERTY(EditAnywhere)
	bool bHideWhileNotOnSpline = true;

	UPROPERTY(BlueprintReadOnly, NotVisible)
	FName BoneName = NAME_None;

	FTransform BaseBoneWorldTransform;

	float CurDistanceAlongSpline = 0;
	float CurTime = 0;
	bool bIsFollowingSpline = false;
	bool bFinished = false;
};

UCLASS(Abstract)
class AGroupMeshSplineActor : AHazeGroupMeshSplineActor
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorDisable(this);

		for (FHazeGroupMeshPerBaseBoneData& PerMeshData : MeshData)
		{
			if (PerMeshData.bHideWhileNotOnSpline)
			{
				Mesh.HideBoneByName(PerMeshData.BoneName, EPhysBodyOp::PBO_None);
			}
		}

		if (bStartEnabled)
			Start();
	}

	UFUNCTION()
	void Start()
	{
		RemoveActorDisable(this);

		FHazePlaySlotAnimationParams PlayAnimParams;
		PlayAnimParams.Animation = AnimationToPlay;
		PlayAnimParams.bLoop = bLoopAnimation;
		Mesh.PlaySlotAnimation(PlayAnimParams);

		for (FHazeGroupMeshPerBaseBoneData& PerMeshData : MeshData)
		{
			PerMeshData.CurDistanceAlongSpline = 0;
			PerMeshData.CurTime = PerMeshData.StartOffset;
			PerMeshData.bIsFollowingSpline = false;
			PerMeshData.bFinished = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		bool bAllFinished = true;

		for (FHazeGroupMeshPerBaseBoneData& PerMeshData : MeshData)
		{
			if (PerMeshData.SplineActor == nullptr)
				continue;

			if (PerMeshData.bFinished)
				continue;

			bAllFinished = false;

			PerMeshData.CurTime += DeltaSeconds;
			if (PerMeshData.CurTime > 0.0)
			{
				if (!PerMeshData.bIsFollowingSpline)
				{
					if (PerMeshData.bHideWhileNotOnSpline)
					{
						Mesh.UnHideBoneByName(PerMeshData.BoneName);
					}

					PerMeshData.bIsFollowingSpline = true;
				}

				PerMeshData.CurDistanceAlongSpline = PerMeshData.Speed * PerMeshData.CurTime;
				PerMeshData.BaseBoneWorldTransform = PerMeshData.SplineActor.Spline.GetWorldTransformAtSplineDistance(PerMeshData.CurDistanceAlongSpline);

				if (PerMeshData.CurDistanceAlongSpline >= PerMeshData.SplineActor.Spline.GetSplineLength())
				{
					if (PerMeshData.bHideWhileNotOnSpline)
					{
						Mesh.HideBoneByName(PerMeshData.BoneName, EPhysBodyOp::PBO_None);
					}

					PerMeshData.bFinished = true;
				}
			}
		}

		if (bAllFinished)
			AddActorDisable(this);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		FString BoneNameBase = "Base_";
		int CurBaseBone = 1;
		int CurBoneIndex = 0;
		int NumBaseBones = 0;

		while (CurBoneIndex != -1)
		{
			FName CurBoneName = FName(f"{BoneNameBase}{CurBaseBone}");
			CurBoneIndex = Mesh.GetBoneIndex(CurBoneName);

			if (CurBoneIndex != -1)
			{
				if (!MeshData.IsValidIndex(NumBaseBones))
					MeshData.Add(FHazeGroupMeshPerBaseBoneData(CurBoneName));

				NumBaseBones++;
				CurBaseBone++;
			}
		}

		// SetNum to remove any additional mesh data not in use
		if (NumBaseBones != MeshData.Num())
			MeshData.SetNum(NumBaseBones);
	}
#endif

	UPROPERTY(EditAnywhere, Category = "GroupMesh")
	bool bStartEnabled = false;

	UPROPERTY(EditAnywhere, Category = "GroupMesh")
	UAnimSequence AnimationToPlay = nullptr;

	UPROPERTY(EditAnywhere, Category = "GroupMesh")
	bool bLoopAnimation = true;

	UPROPERTY(EditAnywhere, Category = "GroupMesh", EditFixedSize)
	TArray<FHazeGroupMeshPerBaseBoneData> MeshData;
};