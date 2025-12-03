UCLASS(Abstract)
class AOilRigForceFieldSpinnerBreakingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformRoot)
	UFauxPhysicsAxisRotateComponent RotateComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike BreakTimeLike;

	UPROPERTY(EditAnywhere, Meta = (MakeEditWidget))
	FTransform BreakTransform;

	UPROPERTY(EditAnywhere)
	bool bPreviewBroken = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewBroken)
			PlatformRoot.SetRelativeLocationAndRotation(BreakTransform.Location, BreakTransform.Rotation);
		else
			PlatformRoot.SetRelativeLocationAndRotation(FVector::ZeroVector, FRotator::ZeroRotator);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BreakTimeLike.BindUpdate(this, n"UpdateBreak");
		BreakTimeLike.BindFinished(this, n"FinishBreak");
	}

	UFUNCTION()
	void Break()
	{
		BreakTimeLike.PlayFromStart();

		UOilRigForceFieldSpinnerBreakingPlatformEffectEventHandler::Trigger_Break(this);
	}

	UFUNCTION()
	private void UpdateBreak(float CurValue)
	{
		FVector Loc = Math::Lerp(FVector::ZeroVector, BreakTransform.Location, CurValue);
		FRotator Rot = Math::LerpShortestPath(FRotator::ZeroRotator, BreakTransform.Rotator(), CurValue);
		PlatformRoot.SetRelativeLocationAndRotation(Loc, Rot);
	}

	UFUNCTION()
	private void FinishBreak()
	{

	}
}

class UOilRigForceFieldSpinnerBreakingPlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Break() {}
}