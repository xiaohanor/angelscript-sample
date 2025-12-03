struct FSummitCrankSpinnerData
{
	UPROPERTY()
	ASummitTopDownMazeRevolvingDoor Spinner;

	UPROPERTY()
	int Direction;
}

class ASummitTopDownCrankForSpinner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent TailAttack;
	
	UPROPERTY(EditAnywhere)
	TArray<FSummitCrankSpinnerData> SpinnerDataArray;

	FRotator Targetotation;

	float AddAmount = 90.0;
	float Movespeed = 2.0;
	float HitTime;
	float HitInterval = 1.0;

	UPROPERTY(EditAnywhere)
	ASummitTopDownMazeRevolvingDoor Spinner;
	
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

		FVector HitToCenterDirection = (Params.HitLocation - MeshRoot.WorldLocation).GetSafeNormal();
		float RollDot = HitToCenterDirection.DotProduct(MeshRoot.RightVector);

		float ActualAddAmount;
		
		if(RollDot < 0)
		{
			for (FSummitCrankSpinnerData& Data : SpinnerDataArray)
			{
				Data.Spinner.ActivateSpinner(Data.Direction * -1);
			}
			ActualAddAmount = AddAmount;
			// Spinner.GoBackward();	
		}	
		else
		{
			for (FSummitCrankSpinnerData& Data : SpinnerDataArray)
			{
				Data.Spinner.ActivateSpinner(Data.Direction * 1);
			}
			ActualAddAmount = -AddAmount;
			// Spinner.GoForward();
		}		

		Targetotation += FRotator(0, ActualAddAmount,0);
		HitTime = Time::GameTimeSeconds + HitInterval;

		//Debug::DrawDebugLine(Params.HitLocation, Params.HitLocation + HitToCenterDirection * 500.0, FLinearColor::Red, 50, 15.0);
		Debug::DrawDebugLine(Params.HitLocation, Params.HitLocation + MeshRoot.ForwardVector * 500.0, FLinearColor::Yellow, 50, 15.0);
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeRotation = Math::QInterpTo(MeshRoot.RelativeRotation.Quaternion(), Targetotation.Quaternion(), DeltaSeconds, 1).Rotator();
	}
}
