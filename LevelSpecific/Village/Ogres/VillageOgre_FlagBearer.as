class AVillageOgre_FlagBearer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent OgreRoot;

	UPROPERTY(DefaultComponent, Attach = OgreRoot)
	UHazeSkeletalMeshComponentBase SkelMeshComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 7000.0;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence Animation;

	UPROPERTY(EditAnywhere, meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float TimeOffsetFraction = 0.0;

	private float AnimStartCrumbTime = 0.0;
	private bool bPlaying = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
#if EDITOR
		SkelMeshComp.EditorPreviewAnim = Animation;
		SkelMeshComp.EditorPreviewAnimTime = Animation.PlayLength * TimeOffsetFraction;
#endif
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> AttachedActors;
		GetAttachedActors(AttachedActors);
		for (AActor Actor : AttachedActors)
		{
			AVillageWobblyPerchPole Pole = Cast<AVillageWobblyPerchPole>(Actor);
			if (Pole != nullptr)
			{
				Pole.AttachToComponent(SkelMeshComp, n"Align");
				Pole.SetActorRelativeRotation(FRotator(0.0, -90.0, 90.0));
			}
		}

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = Animation;
		AnimParams.BlendTime = 0.0;
		AnimParams.bLoop = true;
		AnimParams.StartTime = Animation.PlayLength * TimeOffsetFraction;
		SkelMeshComp.PlaySlotAnimation(AnimParams);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float Position = Math::Wrap(Time::PredictedGlobalCrumbTrailTime + Animation.PlayLength * TimeOffsetFraction, 0.0, Animation.PlayLength);
		SkelMeshComp.SetSlotAnimationPosition(Animation, Position);
	}
}