enum ESummitFruitPressStatueWheelType
{
	Left,
	Right
}

class ASummitFruitPressDragonStatue : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent BaseRotationRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRotationRoot)
	UStaticMeshComponent WheelMesh;
	
	UPROPERTY(DefaultComponent, Attach = BaseRotationRoot)
	USceneComponent RightWingRoot;

	UPROPERTY(DefaultComponent, Attach = BaseRotationRoot)
	USceneComponent LeftWingRoot;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(DefaultComponent)
	UHazeCapabilityComponent CapabilityComp;
	default CapabilityComp.DefaultCapabilities.Add(n"SummitFruitPressDragonStatueRotateCapability");
	default CapabilityComp.DefaultCapabilities.Add(n"SummitFruitPressDragonStatueWingsCapability");

	UPROPERTY(EditAnywhere)
	AMeltableCounterWeight CounterWeight1;

	UPROPERTY(EditAnywhere)
	ASummitLinkedChain LinkedChain1;

	UPROPERTY(EditAnywhere)
	AMeltableCounterWeight CounterWeight2;

	UPROPERTY(EditAnywhere)
	ASummitLinkedChain LinkedChain2;
	
	UPROPERTY(EditAnywhere)
	bool bPreviewEndState;

	UPROPERTY(EditAnywhere)
	ARespawnPointVolume CompletedRespawn;

	UPROPERTY(EditInstanceOnly)
	TArray<ASummitFruitPressStatueWheels> LeftWheels;
	UPROPERTY(EditInstanceOnly)
	TArray<ASummitFruitPressStatueWheels> RightWheels;

	UPROPERTY()
	FRuntimeFloatCurve RotateBaseCurve;
	default RotateBaseCurve.AddDefaultKey(0.0, 0.0);
	default RotateBaseCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	FRuntimeFloatCurve RotateWingCurve;
	default RotateWingCurve.AddDefaultKey(0.0, 0.0);
	default RotateWingCurve.AddDefaultKey(0.5, 0.5);
	default RotateWingCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY()
	UForceFeedbackEffect WingRumble;

	UPROPERTY()
	UForceFeedbackEffect WingRumbleOneShot;

	UPROPERTY()
	UForceFeedbackEffect StatueRumble;
	
	UPROPERTY()
	UForceFeedbackEffect StatueRumbleOneShot;


	UPROPERTY()
	TSubclassOf<UCameraShakeBase> WingsCameraShake;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> StatueCameraShakeFinish;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> StatueCameraShakeStart;
	
	UPROPERTY()
	TSubclassOf<UCameraShakeBase> StatueCameraShakeLoop;

	bool bWeightTwoFallen;
	bool bWeightOneFallen;
	bool bCompletedWings;
	bool bCompletedRotation;
	int WeightCounter;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewEndState)
		{
			RightWingRoot.RelativeRotation = FRotator(0);
			LeftWingRoot.RelativeRotation = FRotator(0);
			BaseRotationRoot.RelativeRotation = FRotator(0,-90,0);
		}
		else
		{
			RightWingRoot.RelativeRotation = FRotator(0, 0, -56.25);
			LeftWingRoot.RelativeRotation = FRotator(0,0,56.25);
			BaseRotationRoot.RelativeRotation = FRotator(0);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CounterWeight1.OnWeightStartsFalling.AddUFunction(this, n"OnWeightStartsFalling");
		CounterWeight2.OnWeightStartsFalling.AddUFunction(this, n"OnWeightStartsFalling");
		if(CompletedRespawn != nullptr)
			CompletedRespawn.AddActorDisable(this);
	}

	void CompetedPuzzle()
	{
		CompletedRespawn.RemoveActorDisable(this);
	}

	UFUNCTION()
	private void OnWeightStartsFalling(AMeltableCounterWeight CounterWeight)
	{
		if (CounterWeight == CounterWeight1)
		{
			bWeightOneFallen = true;
			USummitFruitPressDragonStatueEffectHandler::Trigger_OnRightWingStartMoving(this, FSummitFruitPressDragonStatueParams(RightWingRoot.WorldLocation));

			if(LinkedChain1 != nullptr)
				LinkedChain1.Links.Last().bIsLocked = false;
		}
		else
		{
			bWeightTwoFallen = true;
			USummitFruitPressDragonStatueEffectHandler::Trigger_OnLeftWingStartMoving(this, FSummitFruitPressDragonStatueParams(LeftWingRoot.WorldLocation));

			if(LinkedChain2 != nullptr)
				LinkedChain2.Links.Last().bIsLocked = false;
		}

		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(StatueCameraShakeStart, Player, ActorLocation, 8000.0, 35000.0);

		WeightCounter++;
		WeightCounter = Math::Clamp(WeightCounter, 0, 2);

		if (WeightCounter == 1)
		{
			AlterWheels(ESummitFruitPressStatueWheelType::Right, true);
		}
		else 
		{
			AlterWheels(ESummitFruitPressStatueWheelType::Left, true);
		}
	}

	void StartLoopingCameraShake(float CurrentIntensity = 1.0)
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.PlayWorldCameraShake(StatueCameraShakeLoop, this, ActorLocation, 20000.0, 50000.0, Scale = CurrentIntensity);
	}

	void StopLoopingCameraShake()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			Player.StopCameraShakeByInstigator(this);
	}


	void AlterWheels(ESummitFruitPressStatueWheelType Type, bool bIsOn)
	{
		TArray<ASummitFruitPressStatueWheels> ChosenArray;

		switch (Type)
		{
			case ESummitFruitPressStatueWheelType::Left:
				ChosenArray = LeftWheels;
				break;
			case ESummitFruitPressStatueWheelType::Right:
				ChosenArray = RightWheels;
				break;
		}

		for (ASummitFruitPressStatueWheels& Wheel : ChosenArray)
		{
			Wheel.ChangeActivationMode(bIsOn);
		}
	}

	UFUNCTION()
	void SetEndState()
	{
		bCompletedRotation = true;
		BaseRotationRoot.RelativeRotation = FRotator(0,-90,0);
		
		bCompletedWings = true;
		RightWingRoot.RelativeRotation = FRotator(RightWingRoot.RelativeRotation.Pitch, RightWingRoot.RelativeRotation.Yaw, 0.0);
		LeftWingRoot.RelativeRotation = FRotator(LeftWingRoot.RelativeRotation.Pitch, LeftWingRoot.RelativeRotation.Yaw, 0.0);

	}
};