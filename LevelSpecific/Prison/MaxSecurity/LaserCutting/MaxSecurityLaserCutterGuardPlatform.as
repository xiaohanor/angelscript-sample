UCLASS(Abstract)
class AMaxSecurityLaserCutterGuardPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PlatformRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike RotateTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RotateTimeLike.BindUpdate(this, n"UpdateRotate");
		RotateTimeLike.BindFinished(this, n"FinishRotate");
	}

	void RevealPlatform()
	{
		RotateTimeLike.Play();
	}

	void HidePlatform()
	{
		RotateTimeLike.Reverse();
	}

	UFUNCTION()
	private void UpdateRotate(float CurValue)
	{
		float Rot = Math::Lerp(0.0, 90.0, CurValue);
		PlatformRoot.SetRelativeRotation(FRotator(Rot, 0.0, 0.0));
	}

	UFUNCTION()
	private void FinishRotate()
	{

	}
}