class ASummitTopDownWheelDoor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent StartPosRoot;

	UPROPERTY(DefaultComponent, Attach = StartPosRoot)
	UStaticMeshComponent StartPosMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndPosRoot;

	UPROPERTY(DefaultComponent, Attach = EndPosRoot)
	UStaticMeshComponent EndPosMesh;

	UPROPERTY(EditAnywhere, Category = "Settings")
	ASummitRollingWheel Wheel;

	UPROPERTY(EditAnywhere, Category = "Settings")
	bool bReverse = false;

	FVector StartPos;
	FVector TargetPos;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MoveSpeed = 0.0005;

	float WheelPosition = 0.0;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike DoorAnim;
	default DoorAnim.Duration = 0.5;
	default DoorAnim.Curve.AddDefaultKey(0,0);
	default DoorAnim.Curve.AddDefaultKey(0.5,1);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Wheel.OnWheelRolled.AddUFunction(this, n"OnWheelRolling");
		StartPos = StartPosRoot.RelativeLocation;
		TargetPos = EndPosRoot.RelativeLocation;

		DoorAnim.BindUpdate(this,n"OnUpdate");
		EndPosMesh.SetVisibility(false);
	}

	UFUNCTION()
	private void OnWheelRolling(float Amount)
	{
		WheelPosition += Amount * MoveSpeed;
		WheelPosition = Math::Clamp(WheelPosition, 0 , 1);
		float Alpha;
		if(bReverse)
			Alpha = 1 - WheelPosition;
		else
			Alpha = WheelPosition;

		StartPosRoot.RelativeLocation = Math::Lerp(StartPos,TargetPos, Alpha);
	
	}

	UFUNCTION()
	void OnUpdate(float Alpha)
	{
		StartPosRoot.RelativeLocation = Math::Lerp(StartPos,TargetPos, Alpha);
	}

	UFUNCTION()
	void PlayFunction()
	{
		DoorAnim.Play();
	}

	UFUNCTION()
	void ReverseFunction()
	{
		DoorAnim.Reverse();
	}
}