class ASummitKnightShieldWallOuterLayer : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent Shields;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	USceneComponent ShieldTarget;

	UPROPERTY(DefaultComponent)
	URotatingMovementComponent RotatingMovement;

	FVector StartLocation;

	FVector TargetLocation;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike MoveAnim;
	default MoveAnim.Duration = 3.0;
	default MoveAnim.Curve.AddDefaultKey(0.0, 0.0);
	default MoveAnim.Curve.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = ActorLocation;

		TargetLocation = ShieldTarget.WorldLocation;

		MoveAnim.BindUpdate(this, n"OnUpdate");
	}

	UFUNCTION()
	private void OnUpdate(float Alpha)
	{
		ActorLocation = Math::Lerp(StartLocation,TargetLocation,Alpha);
	}

	UFUNCTION()
	void PlayFunction()
	{
		MoveAnim.Play();
	}
};