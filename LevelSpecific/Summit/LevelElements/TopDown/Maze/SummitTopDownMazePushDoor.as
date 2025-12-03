class ASummitTopDownMazePushDoor : AHazeActor
{	
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent PushGate;

	UPROPERTY(DefaultComponent, Attach = PushGate) 
	UStaticMeshComponent MoveGate;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UBillboardComponent MoveTarget;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent RollAttack;

	FVector PositionA;
	FVector PositionB;

	bool bAtPositionB;

	UPROPERTY(EditAnywhere)
	FHazeTimeLike PushAnim;
	default PushAnim.bFlipFlop = true;
	default PushAnim.Duration = 2.0;
	default PushAnim.Curve.AddDefaultKey(0.0, 0.0);
	default PushAnim.Curve.AddDefaultKey(1.0, 1.0);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RollAttack.OnHitByRoll.AddUFunction(this, n"HitByRoll");
		PushAnim.BindUpdate(this, n"PushUpdate");
		PushAnim.BindFinished(this, n"PushFinished");

		PositionA = MeshRoot.GetWorldLocation();
		PositionB = MoveTarget.GetWorldLocation();
	}


	UFUNCTION()
	private void HitByRoll(FRollParams Params)
	{
		float RollDot = Params.RollDirection.DotProduct(MeshRoot.RightVector);
		Print("RollDot: " + RollDot);

		if(PushAnim.GetValue() < 0.5 && RollDot < 0)
			PushAnim.Play();
		else if(PushAnim.GetValue() > 0.5 && RollDot > 0)
			PushAnim.Reverse();
	}

	UFUNCTION()
	void PushFinished ()
	{
		PushAnim.Stop();
	}

	UFUNCTION()
	void PushUpdate (float Alpha)

	{
		MeshRoot.SetRelativeLocation(Math::Lerp(PositionA,PositionB,Alpha));
		
	}

	
}