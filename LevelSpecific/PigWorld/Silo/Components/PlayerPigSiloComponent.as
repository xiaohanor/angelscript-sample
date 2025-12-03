asset CameraBlend_PigSilo of UCameraDefaultBlend
{
	bLockSourceViewRotation = false;
}

event void FPlayerPigSiloObstacleCollisionEvent(const APigSiloObstacle Obstacle);

class UPlayerPigSiloComponent : UActorComponent
{
	UPROPERTY(Category = "VFX")
	UNiagaraSystem SlideDashVFX;

	UPROPERTY()
	FPlayerPigSiloObstacleCollisionEvent OnObstacleCollision;

	UPROPERTY()
	UForceFeedbackEffect ObstacleCollisionFF;

	UPROPERTY()
	UForceFeedbackEffect JumpFF;

	AHazePlayerCharacter PlayerOwner;

	private APigSiloPlatform PigSiloPlatform;

	access PigSiloJump = private, UPigSiloJumpCapability;
	access : PigSiloJump bool bJumping;

	access PigSiloTumble = private, UPigSiloTumbleCapability;
	access : PigSiloTumble bool bTumbling;

	UHazeSplineComponent CurrentSpline = nullptr;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION()
	void Start(APigSiloPlatform SiloPlatformActor)
	{
		PigSiloPlatform = SiloPlatformActor;
		CurrentSpline = Recursive_GetFirstSpline(PigSiloPlatform.Spline);
	}

	UFUNCTION(CrumbFunction)
	void Crumb_SetCurrentSpline(UHazeSplineComponent Spline)
	{
		CurrentSpline = Spline;
	}

	APigSiloPlatform GetSiloPlatform() property
	{
		return PigSiloPlatform;
	}

	bool IsSiloMovementActive() const
	{
		return PigSiloPlatform != nullptr;
	}

	bool IsJumping() const
	{
		return bJumping;
	}

	bool IsTumbling() const
	{
		return bTumbling;
	}

	UHazeSplineComponent Recursive_GetFirstSpline(UHazeSplineComponent InSplineComponent) const
	{
		if (InSplineComponent.StartConnection.ConnectTo.IsNull())
			return InSplineComponent;

		UHazeSplineComponent OutSplineComponent = UHazeSplineComponent::Get(InSplineComponent.StartConnection.ConnectTo.Get());
		if (OutSplineComponent == nullptr)
			return InSplineComponent;

		return OutSplineComponent;
	}
}