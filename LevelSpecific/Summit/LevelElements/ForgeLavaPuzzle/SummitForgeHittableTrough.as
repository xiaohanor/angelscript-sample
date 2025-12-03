class ASummitForgeHittableTrough : AHazeActor 
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttack;

	FRotator Targetotation;
	float AddAmount = 90.0;
	float Movespeed = 2.0;
	float HitTime;
	float HitInterval = 2.0;

	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
		TailAttack.OnHitByRoll.AddUFunction(this, n"OnHit");
		Targetotation = MeshRoot.RelativeRotation;	
		
	}

	
	UFUNCTION()
	private void OnHit(FRollParams Params)
	{
//		MeshRoot.AddRelativeRotation(FRotator (0, TargetRotation,0));
		if (Time::GameTimeSeconds < HitTime)
			return;	

		FVector HitToCenterDirection = (Params.HitLocation - ActorLocation).GetSafeNormal();
		float CenterDot = MeshRoot.ForwardVector.DotProduct(HitToCenterDirection);
		float RollDot = Params.RollDirection.DotProduct(MeshRoot.RightVector);
		Print("CenterDot: " + CenterDot);
		Print("RollDot: " + RollDot);

		float ActualAddAmount;

		if(RollDot > 0)
		{
			if(CenterDot > 0)
				ActualAddAmount = AddAmount;				
			else
				ActualAddAmount = -AddAmount;

		}
		else
		{
			if(CenterDot > 0)
				ActualAddAmount = -AddAmount;				
			else
				ActualAddAmount = AddAmount;
		}
		Targetotation += FRotator(0, ActualAddAmount,0);
		HitTime = Time::GameTimeSeconds + HitInterval;
	//	Debug::DrawDebugLine(Params.HitLocation, Params.HitLocation + HitToCenterDirection * 500.0, FLinearColor::Red, 10, 5.0);
	//	Debug::DrawDebugLine(Params.HitLocation, Params.HitLocation + ActorForwardVector * 500.0, FLinearColor::Yellow, 10, 5.0);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeRotation = Math::QInterpTo(MeshRoot.RelativeRotation.Quaternion(), Targetotation.Quaternion(), DeltaSeconds, 1).Rotator();
	}
}