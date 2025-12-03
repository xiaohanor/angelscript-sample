UCLASS(Abstract)
class AVillageOgre_Canal : AVillageOgreBase
{
	UPROPERTY(EditDefaultsOnly)
	UAnimSequence FlailAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence BreakThroughAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence StuckEnterAnim;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence StuckMhAnim;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect StuckOnGrateFF;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike StuckOnGrateEnterTimeLike;

	FTransform StuckStartTransform;
	FTransform StuckEndTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		StuckOnGrateEnterTimeLike.BindUpdate(this, n"UpdateStuckOnGrateEnter");
	}

	void Jump(ASplineActor Spline) override
	{
		Super::Jump(Spline);
		
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = FlailAnim;
		AnimParams.bLoop = true;
		PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
	void BreakThroughGrate()
	{
		FHazeAnimationDelegate BreakThroughAnimDelegate;
		BreakThroughAnimDelegate.BindUFunction(this, n"BreakThroughAnimFinished");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = BreakThroughAnim;
		PlaySlotAnimation(FHazeAnimationDelegate(), BreakThroughAnimDelegate, AnimParams);
	}

	UFUNCTION()
	private void BreakThroughAnimFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = FlailAnim;
		AnimParams.bLoop = true;
		PlaySlotAnimation(AnimParams);
	}

	UFUNCTION()
	void GetStuckOnGrate(AActor RefActor)
	{
		FHazeAnimationDelegate GetStuckAnimDelegate;
		GetStuckAnimDelegate.BindUFunction(this, n"StuckEnterAnimFinished");

		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = StuckEnterAnim;
		PlaySlotAnimation(FHazeAnimationDelegate(), GetStuckAnimDelegate, AnimParams);
		
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(StuckOnGrateFF, false, true, this);
		}

		StuckStartTransform = SkelMeshComp.WorldTransform;
		StuckEndTransform = RefActor.ActorTransform;

		StuckOnGrateEnterTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateStuckOnGrateEnter(float CurValue)
	{
		FVector Loc = Math::Lerp(StuckStartTransform.Location, StuckEndTransform.Location, CurValue);
		FRotator Rot = Math::LerpShortestPath(StuckStartTransform.Rotator(), StuckEndTransform.Rotator(), CurValue);
		SkelMeshComp.SetWorldLocationAndRotation(Loc, Rot);
	}

	UFUNCTION()
	private void StuckEnterAnimFinished()
	{
		FHazePlaySlotAnimationParams AnimParams;
		AnimParams.Animation = StuckMhAnim;
		AnimParams.bLoop = true;
		PlaySlotAnimation(AnimParams);
	}
}