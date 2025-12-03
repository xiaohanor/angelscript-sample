event void FMotherKiteClampEvent();

UCLASS(Abstract)
class AMotherKiteClamp : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LeftClampRoot;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RightClampRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike OpenClampsTimeLike;

	UPROPERTY()
	FMotherKiteClampEvent OnOpened;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenClampsTimeLike.BindUpdate(this, n"UpdateOpenClamps");
		OpenClampsTimeLike.BindFinished(this, n"FinishOpenClamp");
	}

	UFUNCTION()
	void OpenClamp()
	{
		Timer::SetTimer(this, n"ActuallyOpen", 0.6);
	}

	UFUNCTION()
	private void ActuallyOpen()
	{
		OpenClampsTimeLike.PlayFromStart();

		BP_OpenClamp();
	}

	UFUNCTION(BlueprintEvent)
	void BP_OpenClamp() {}

	UFUNCTION()
	private void UpdateOpenClamps(float CurValue)
	{
		float Rot = Math::Lerp(0.0, 179.9, CurValue);
		LeftClampRoot.SetRelativeRotation(FRotator(0.0, 0.0, -Rot));
		RightClampRoot.SetRelativeRotation(FRotator(0.0, 0.0, Rot));
	}

	UFUNCTION()
	private void FinishOpenClamp()
	{
		OnOpened.Broadcast();
	}
}