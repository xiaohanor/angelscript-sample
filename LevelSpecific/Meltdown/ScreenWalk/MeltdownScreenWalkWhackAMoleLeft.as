event void FOnWhacked();

class AMeltdownScreenWalkWhackAMoleLeft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UMeltdownScreenWalkResponseComponent ResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Stump;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent StumpTarget;

	FOnWhacked LeftWhacked;

	FHazeTimeLike MoveWhack;
	default MoveWhack.Duration = 0.5;
	default MoveWhack.UseLinearCurveZeroToOne();

	FVector StartLocation;
	FVector TargetLocation;

	UPROPERTY(EditAnywhere)
	AMeltdownScreenWalkWhackAMoleRight OtherWhack;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		StartLocation = Stump.RelativeLocation;
		TargetLocation = StumpTarget.RelativeLocation;

		MoveWhack.BindUpdate(this, n"OnUpdate");

		ResponseComp.OnJumpTrigger.AddUFunction(this, n"OnWhacked");

		OtherWhack.RightWhacked.AddUFunction(this, n"OtherWhacked");
	}

	UFUNCTION()
	private void OnUpdate(float CurrentValue)
	{
		Stump.SetRelativeLocation(Math::Lerp(StartLocation,TargetLocation,CurrentValue));
	}

	UFUNCTION()
	private void OnWhacked()
	{
		LeftWhacked.Broadcast();
		MoveWhack.PlayFromStart();
	}

	UFUNCTION()
	private void OtherWhacked()
	{
		MoveWhack.ReverseFromEnd();
	}


};