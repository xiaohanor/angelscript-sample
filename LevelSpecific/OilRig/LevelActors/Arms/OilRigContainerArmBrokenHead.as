UCLASS(Abstract)
class AOilRigContainerArmBrokenHead : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent HeadRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike WiggleTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WiggleTimeLike.BindUpdate(this, n"UpdateWiggle");
		WiggleTimeLike.BindFinished(this, n"FinishWiggle");
		
		StartWiggling();
	}

	void StartWiggling()
	{
		WiggleTimeLike.PlayFromStart();

		UOilRigContainerArmBrokenHeadEffectEventHandler::Trigger_StartWiggling(this);
	}

	UFUNCTION()
	private void UpdateWiggle(float CurValue)
	{
		float Rot = Math::Lerp(0.0, 40.0, CurValue);
		HeadRoot.SetRelativeRotation(FRotator(Rot, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishWiggle()
	{
		StartWiggling();
	}
}

class UOilRigContainerArmBrokenHeadEffectEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent)
	void StartWiggling() {}
}