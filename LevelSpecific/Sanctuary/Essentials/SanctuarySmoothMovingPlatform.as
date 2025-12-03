class ASanctuarySmoothMovingPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USanctuarySmoothMovingComponent MovingComp;

	UPROPERTY(DefaultComponent, Attach = MovingComp)
	USanctuaryFloatingSceneComponent FloatingSceneComp;

	UPROPERTY(DefaultComponent)
	USanctuaryInterfaceComponent InterfaceComp;

	UPROPERTY(EditAnywhere)
	FTransform TargetTransform;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MovingComp.OnTargetReached.AddUFunction(this, n"HandleTargetReached");
		InterfaceComp.OnActivated.AddUFunction(this, n"HandeleActivated");
		InterfaceComp.OnDeactivated.AddUFunction(this, n"HandeleDeactivated");
	}

	UFUNCTION()
	private void HandeleActivated(AActor Caller)
	{
		MovingComp.SetRelativeTransformTarget(TargetTransform);
	}

	UFUNCTION()
	private void HandeleDeactivated(AActor Caller)
	{
		MovingComp.SetRelativeTransformTarget(FTransform::Identity);
	}

	UFUNCTION()
	private void HandleTargetReached()
	{
	}
};