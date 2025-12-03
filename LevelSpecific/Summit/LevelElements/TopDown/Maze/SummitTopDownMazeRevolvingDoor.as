class ASummitTopDownMazeRevolvingDoor : AHazeActor
{
	UPROPERTY(DefaultComponent,RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent)
	UTeenDragonTailAttackResponseComponent RollAttack;

	UPROPERTY(EditAnywhere)
	ASummitTopDownMazeRevolvingDoor RollSibling;

	FRotator SiblingRotator;

	FRotator TargetRotation;

	float AddAmount = -90.0;
	float Movespeed = 4.0;
	float HitTime;
	float HitInterval = 2.0;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	//	RollAttack.OnHitByRoll.AddUFunction(this, n"OnHitByRoll");

		TargetRotation = MeshRoot.RelativeRotation;
		if (RollSibling != nullptr)
			SiblingRotator = RollSibling.MeshRoot.RelativeRotation;

	}

	// UFUNCTION()
	// private void OnHitByRoll(FRollParams Params)
	// {
	// 	if (Time::GameTimeSeconds < HitTime)
	// 		return;	

	// 	float RollDot = Params.RollDirection.DotProduct(PushGate.ForwardVector);
	// 	Print("RollDot: " + RollDot);


	// 	if(RollDot > 0)
	// 	{
	// 		if(RollDot < 0)
	// 		{
	// 			ActualAddAmount = AddAmount;
	// 		}		
	// 		else
	// 		{
	// 			ActualAddAmount = -AddAmount;
	// 		}

	// 	}
	// 	else
	// 	{
	// 		if(RollDot > 0)
	// 		{
	// 			ActualAddAmount = -AddAmount;
	// 		}				
	// 		else
	// 		{
	// 			ActualAddAmount = AddAmount;
	// 		}
	// 	}

	// 	TargetRotation += FRotator(0, ActualAddAmount,0);
	// 	if(RollSibling != nullptr)
	// 	RollSibling.TargetRotation -= FRotator(0, ActualAddAmount,0);

	// 	Print("SiblingRotator: " + SiblingRotator);
	// 	Print("Targetotation: " + TargetRotation);

	// 	HitTime = Time::GameTimeSeconds + HitInterval;
	// 	Debug::DrawDebugLine(Params.HitLocation, Params.HitLocation + ActorForwardVector * 500.0, FLinearColor::Yellow, 10, 5.0);
	// }

	UFUNCTION()
	void ActivateSpinner(int Direction)
	{
 		TargetRotation += FRotator(0,AddAmount * Direction,0);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeRotation = Math::QInterpTo(MeshRoot.RelativeRotation.Quaternion(), TargetRotation.Quaternion(), DeltaSeconds, 1).Rotator();
	}

}
