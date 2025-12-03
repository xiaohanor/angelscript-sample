UCLASS(Abstract)
class AGameShowArenaPushingPlatform : AGameShowArenaDynamicObstacleBase
{
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseRailingRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRailingRoot)
	UStaticMeshComponent BaseRailing;

	UPROPERTY(DefaultComponent, Attach = BaseRailingRoot)
	USceneComponent RailingRoot;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	UStaticMeshComponent RailingMesh;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	USceneComponent PlatformRotationRoot;
	default PlatformRotationRoot.bAbsoluteRotation = true;

	UPROPERTY(DefaultComponent, Attach = RailingRoot)
	USceneComponent PlatformMeshRoot;

	UPROPERTY(DefaultComponent, Attach = PlatformMeshRoot)
	UStaticMeshComponent PlatformMesh;

	UPROPERTY(DefaultComponent, Attach = PlatformMesh)
	UStaticMeshComponent PlatformDetailMesh01;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;

	UPROPERTY(EditInstanceOnly)
	float StartDelay = 0;

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Timer::SetTimer(this, n"StartPushingPlatformTimer", StartDelay);
	}

	UFUNCTION()
	private void StartPushingPlatformTimer()
	{
		StartPushingPlatformTimeline();
	}

	UFUNCTION(BlueprintEvent)
	void StartPushingPlatformTimeline()
	{
		UGameShowArenaPushingPlatformEffectHandler::Trigger_OnPushStarted(this);
	}
};