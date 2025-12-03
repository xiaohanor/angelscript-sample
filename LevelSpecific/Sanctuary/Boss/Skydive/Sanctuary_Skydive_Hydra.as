event void FSanctuarySkydiveHydraActivatedSignature();

UCLASS(Abstract)
class ASanctuary_Skydive_Hydra : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh, AttachSocket = "Head")
	UHazeSphereComponent ThroatHazeSphere;

	UPROPERTY(EditAnywhere)
	FHazePlaySlotAnimationParams AnimationParams;

	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent QueueComp;

	UPROPERTY()
	FSanctuarySkydiveHydraActivatedSignature OnActivated;

	FTransform OGTransform;

	UPROPERTY(EditAnywhere)
	bool bSwallowHydra;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Mesh.EditorPreviewAnim = AnimationParams.Animation;
		Mesh.EditorPreviewAnimTime = AnimationParams.StartTime;
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OGTransform = GetActorTransform();
		AddActorDisable(this);
		//Mesh.PlaySlotAnimation(AnimationParams);
		
	}

	UFUNCTION()
	void EnableHydra()
	{
		//SetActorTransform(OGTransform);
		RemoveActorDisable(this);
	}

	UFUNCTION()
	void HideNeck()
	{
		if(bSwallowHydra)
		{
			Mesh.SetScalarParameterValueOnMaterials(n"bIsSwallowHydra", 1);
		}
		
		Mesh.SetScalarParameterValueOnMaterials(n"ThroatHidePlaneOffset", 8000.0);
		//QueueComp.Duration(0.15, this, n"UnHideHazeUpdate");
		QueueComp.Duration(0.3, this, n"OpenHydraMouthHoleUpdate");

	}

	UFUNCTION()
	private void UnHideHazeUpdate(float Alpha)
	{
		
	}

	UFUNCTION()
	private void OpenHydraMouthHoleUpdate(float Alpha)
	{
		float Radius = Math::EaseOut(0.0, 2500.0, Alpha, 2.0);

		FLinearColor Color = FLinearColor(8671.815430, 58.119076, 3.523574, Radius);
		Mesh.SetColorParameterValueOnMaterials(n"ThroatSphereMaskPos", Color);

		float Opacity = Math::Lerp(1.0, 0.5, Alpha);
		ThroatHazeSphere.SetOpacityValue(Opacity);
	}

	UFUNCTION()
	void PlaySlotAnimationLevelBP(FHazePlaySlotAnimationParams AnimParams)
	{	
		Mesh.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
	void ActivateLights()
	{
		OnActivated.Broadcast();
	}
};
