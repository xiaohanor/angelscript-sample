class ASummitFruitPress : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent RotationRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent ShakeRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	USceneComponent WheelAttachRoot;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UBoxComponent Overlap;
	bool bMioOnPlatform;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent RollHitForwardMesh;

	UPROPERTY(DefaultComponent, Attach = RollHitForwardMesh)
	UTeenDragonTailAttackResponseComponent ForwardRollResponseComp;
	default ForwardRollResponseComp.bShouldStopPlayer = true;
	default ForwardRollResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent, Attach = RotationRoot)
	UStaticMeshComponent RollHitBackwardMesh;

	UPROPERTY(DefaultComponent, Attach = RollHitBackwardMesh)
	UTeenDragonTailAttackResponseComponent BackwardRollResponseComp;
	default BackwardRollResponseComp.bShouldStopPlayer = true;
	default BackwardRollResponseComp.bIsPrimitiveParentExclusive = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 50000.0;

	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TempLogTransformComp;

#if EDITOR
	UPROPERTY(DefaultComponent)
	USummitFruitPressDummyComponent DummyComp;
#endif

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve RotationCurve;
	default RotationCurve.AddDefaultKey(0.0, 0.0);
	default RotationCurve.AddDefaultKey(1.0, 1.0);

	UPROPERTY(EditAnywhere, Category = "Settings")
	float WheelRotationSpeed = 1.5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int TimesHitToCompleteTurn = 8;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float TimeToCompleteRotation = 2.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int PitchShakeFrequency = 5;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int RollShakeFrequency = 3;

	UPROPERTY(EditAnywhere, Category = "Settings")
	int YawShakeFrequency = 9;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float ShakeDuration = 1.7;

	UPROPERTY(EditAnywhere, Category = "Settings")
	FRotator StartShakeAmplitude = FRotator(0.18, 0.017, 0.7);

	float TimeLastHitByRoll;
	bool bIsRotating = false;
	bool bLastHitForwards = false;

	FQuat TargetRotation;
	FQuat StartRotation;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ForwardRollResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRollForwards");
		BackwardRollResponseComp.OnHitByRoll.AddUFunction(this, n"OnHitByRollBackwards");

		TargetRotation = RotationRoot.RelativeRotation.Quaternion();

		Overlap.OnComponentBeginOverlap.AddUFunction(this, n"OnComponentBeginOverlap");
		Overlap.OnComponentEndOverlap.AddUFunction(this, n"OnComponentEndOverlap");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRollBackwards(FRollParams Params)
	{
		GetHitByRoll(false, Params.HitLocation, Params.PlayerInstigator);
	}

	UFUNCTION()
	private void OnComponentBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                     UPrimitiveComponent OtherComp, int OtherBodyIndex,
	                                     bool bFromSweep, const FHitResult&in SweepResult)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor).IsMio())
			bMioOnPlatform = true;
	}

	UFUNCTION()
	private void OnComponentEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                                   UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{
		if (Cast<AHazePlayerCharacter>(OtherActor).IsMio())
			bMioOnPlatform = false;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnHitByRollForwards(FRollParams Params)
	{
		GetHitByRoll(true, Params.HitLocation, Params.PlayerInstigator);
	}

	private void GetHitByRoll(bool bForwards, FVector HitLocation, AHazePlayerCharacter Player)
	{
		FVector FlatHitLocation = HitLocation.ConstrainToPlane(FVector::UpVector);
		FVector FlatPlayerLocation = Player.ActorLocation.ConstrainToPlane(FVector::UpVector);
		FVector DirToHit = (FlatPlayerLocation - FlatHitLocation).GetSafeNormal();

		FVector HitCompareVector = bForwards ? 
			RollHitForwardMesh.UpVector : 
			RollHitBackwardMesh.UpVector;

		if(DirToHit.DotProduct(HitCompareVector) < 0.4)
			return;
		
		float AdditionalYaw = 0.0;
		if(bForwards)
			AdditionalYaw = -360.0 / TimesHitToCompleteTurn;
		else
			AdditionalYaw = 360.0 / TimesHitToCompleteTurn;

		StartRotation = RotationRoot.RelativeRotation.Quaternion();
		TargetRotation *= FRotator(0.0, AdditionalYaw, 0.0).Quaternion();

		FSummitFruitPressOnHitByDragonParams HitParams;
		HitParams.HitLocation = HitLocation;
		HitParams.HitNormal = HitCompareVector;
		USummitFruitPressEventHandler::Trigger_OnHitByDragon(this, HitParams);

		bIsRotating = true;
		bLastHitForwards = bForwards;
		TimeLastHitByRoll = Time::GameTimeSeconds;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		float TimeSinceHit = Time::GetGameTimeSince(TimeLastHitByRoll);
		if(TimeSinceHit < TimeToCompleteRotation)
			RotateTowardsTarget(TimeSinceHit);
		else if(bIsRotating)
			StopRotating();

		if(TimeSinceHit < ShakeDuration)
			ShakePlatform(TimeSinceHit);
	}

	private void RotateTowardsTarget(float TimeSinceHit)
	{
		float AlphaTime = TimeSinceHit / TimeToCompleteRotation;
		float AlphaToReachTarget = RotationCurve.GetFloatValue(AlphaTime);
		
		float LastYaw = RotationRoot.RelativeRotation.Yaw;
		RotationRoot.RelativeRotation = FQuat::Slerp(StartRotation, TargetRotation, AlphaToReachTarget).Rotator();

		float AbsDeltaYaw = Math::Abs(RotationRoot.RelativeRotation.Yaw) - Math::Abs(LastYaw);
		AbsDeltaYaw = Math::Abs(AbsDeltaYaw);
		if(bLastHitForwards)
			AbsDeltaYaw *= -1;
		FRotator DeltaRotation = FRotator(0, 0, AbsDeltaYaw * WheelRotationSpeed);
		FQuat WheelQuat = WheelAttachRoot.RelativeRotation.Quaternion();
		WheelQuat *= DeltaRotation.Quaternion();
		WheelAttachRoot.SetRelativeRotation(WheelQuat);

		if (bMioOnPlatform)
		{
			PrintToScreen(f"{AlphaToReachTarget=}");
			FHazeFrameForceFeedback FF;
			FF.LeftMotor = Math::Sin(Time::GameTimeSeconds * 2.5) * AlphaToReachTarget;
			FF.RightMotor = Math::Sin(-Time::GameTimeSeconds * 2.5) * AlphaToReachTarget;
			Game::Mio.SetFrameForceFeedback(FF);
		}
	}

	private void ShakePlatform(float TimeSinceHit)
	{
		float AlphaTime = TimeSinceHit / ShakeDuration;
		FRotator ShakeAmplitude = Math::LerpShortestPath(StartShakeAmplitude, FRotator::ZeroRotator, AlphaTime);

		float PitchAmplitude = Math::Sin(((TimeSinceHit * TWO_PI) / ShakeDuration) * PitchShakeFrequency) * ShakeAmplitude.Pitch;
		float YawAmplitude = Math::Sin(((TimeSinceHit * TWO_PI) / ShakeDuration)  * YawShakeFrequency) * ShakeAmplitude.Yaw;
		float RollAmplitude = -Math::Sin(((TimeSinceHit * TWO_PI) / ShakeDuration) * RollShakeFrequency) * ShakeAmplitude.Roll;

		ShakeRoot.RelativeRotation = FRotator(PitchAmplitude, YawAmplitude, RollAmplitude);
	}

	private void StopRotating()
	{
		bIsRotating = false;
		USummitFruitPressEventHandler::Trigger_OnStoppedRotating(this);
	}
};

#if EDITOR
class USummitFruitPressDummyComponent : UActorComponent {};
class USummitFruitPressComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USummitFruitPressDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto Comp = Cast<USummitFruitPressDummyComponent>(Component);
		if(Comp == nullptr)
			return;

		auto FruitPress = Cast<ASummitFruitPress>(Comp.Owner);
		if(FruitPress == nullptr)
			return;
		
		float AccumulatedRotation = 0.0;
		for(int i = 0; i < FruitPress.TimesHitToCompleteTurn - 1; i++)
		{
			float RotationAngle = 360.0 / FruitPress.TimesHitToCompleteTurn;
			AccumulatedRotation += RotationAngle;

			FVector NewForward = FruitPress.ActorForwardVector.RotateAngleAxis(AccumulatedRotation, FruitPress.ActorUpVector);
			FQuat Rotation = FQuat::MakeFromX(NewForward);

			const float UpOffset = 2450.0;
			const float ForwardOffset = 5300.0;
			const FVector BoxExtents = FVector(500, 500, 250);

			FVector BoxOrigin = FruitPress.ActorLocation 
				+ Rotation.UpVector * UpOffset
				+ Rotation.ForwardVector * ForwardOffset;
			
			DrawWireBox(BoxOrigin, BoxExtents, Rotation, FLinearColor::Green, 20, false);
		}
	}
}
#endif