UCLASS(Abstract)
class AVillageOgre_Cosmetic : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSkeletalMeshComponentBase MeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 7000.0;

	UPROPERTY(EditAnywhere)
	UAnimSequence Animation;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		MeshComp.EditorPreviewAnim = Animation;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Animation;
		AnimParams.BlendTime = 0.0;
		AnimParams.bLoop = true;
		AnimParams.StartTime = Math::RandRange(0.0, Animation.PlayLength);
		MeshComp.PlaySlotAnimation(AnimParams);
	}
}