UCLASS(Abstract)
class ARedSpacePressurePlatePlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveTimeLike;

	UPROPERTY(EditAnywhere)
	FVector TargetLocation = FVector(0.0, 0.0, 850);

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveTimeLike.BindUpdate(this, n"UpdateMove");
		MoveTimeLike.BindFinished(this, n"FinishMove");
	}

	UFUNCTION()
	private void UpdateMove(float CurValue)
	{
		FVector Loc = Math::Lerp(FVector::ZeroVector, TargetLocation, CurValue);
		PlatformRoot.SetRelativeLocation(Loc);
	}

	UFUNCTION()
	private void FinishMove()
	{
	}

	UFUNCTION()
	void Activate()
	{
		if (bActive)
			return;

		bActive = true;
		MoveTimeLike.Play();

		URedSpacePressurePlatePlatformEffectEventHandler::Trigger_Activated(this);
	}

	UFUNCTION()
	void Deactivate()
	{
		if (!bActive)
			return;

		bActive = false;
		MoveTimeLike.Reverse();

		URedSpacePressurePlatePlatformEffectEventHandler::Trigger_Deactivated(this);
	}
}

class URedSpacePressurePlatePlatformEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void Activated() {}
	UFUNCTION(BlueprintEvent)
	void Deactivated() {}
}