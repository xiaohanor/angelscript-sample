UCLASS(Abstract)
class APrisonBossFloorHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HatchRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenHatchTimeLike;

	TArray<UStaticMeshComponent> HatchMeshes;

	bool bClosed = true;
	float OpenOffset = 410.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HatchRoot.GetChildrenComponentsByClass(UStaticMeshComponent, true, HatchMeshes);

		OpenHatchTimeLike.BindUpdate(this, n"UpdateOpenHatch");
	}

	UFUNCTION()
	void Close()
	{
		OpenHatchTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void SnapOpen()
	{
		bool bOffset = false;
		for (UStaticMeshComponent MeshComp : HatchMeshes)
		{
			FVector OffsetDir = MeshComp.RelativeRotation.ForwardVector;
			if (bOffset)
				OffsetDir = OffsetDir.RotateAngleAxis(45.0, FVector::UpVector);

			MeshComp.SetRelativeLocation(OffsetDir * OpenOffset);
			bOffset = !bOffset;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateOpenHatch(float CurValue)
	{
		bool bOffset = false;
		for (UStaticMeshComponent MeshComp : HatchMeshes)
		{
			FVector OffsetDir = MeshComp.RelativeRotation.ForwardVector;
			if (bOffset)
				OffsetDir = OffsetDir.RotateAngleAxis(45.0, FVector::UpVector);

			FVector Loc = Math::Lerp(FVector::ZeroVector, OffsetDir * OpenOffset, CurValue);
			MeshComp.SetRelativeLocation(Loc);
			bOffset = !bOffset;
		}

		float Rot = Math::Lerp(0.0, 180.0, CurValue);
		HatchRoot.SetRelativeRotation(FRotator(0.0, Rot, 0.0));
	}

	UFUNCTION()
	void SnapClosed()
	{
		HatchRoot.SetRelativeRotation(FRotator(0.0, 180, 0.0));
		for (UStaticMeshComponent MeshComp : HatchMeshes)
		{
			MeshComp.SetRelativeLocation(FVector::ZeroVector);
		}
	}
}