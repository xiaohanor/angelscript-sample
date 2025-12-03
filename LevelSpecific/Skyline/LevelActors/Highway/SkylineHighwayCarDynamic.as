class ASkylineHighwayCarDynamic : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UFauxPhysicsTranslateComponent TranslateCompZ;
	default TranslateCompZ.bConstrainX = true;
	default TranslateCompZ.bConstrainY = true;
	default TranslateCompZ.SpringStrength = 50.0;

	UPROPERTY(DefaultComponent, Attach = TranslateCompZ)
	UFauxPhysicsConeRotateComponent ConeRotateComp;
	default ConeRotateComp.LocalConeDirection = -FVector::UpVector;
	default ConeRotateComp.Friction = 5.0;
	default ConeRotateComp.bConstrainTwist = true;
//	default ConeRotateComp.SpringStrength = 50.0;
/*
	UPROPERTY(DefaultComponent, Attach = TranslateCompZ)
	UFauxPhysicsAxisRotateComponent RotateCompX;
	default RotateCompX.LocalRotationAxis = FVector::ForwardVector;
	default RotateCompX.Friction = 4.0;
//	default RotateCompX.SpringStrength = 50.0;

	UPROPERTY(DefaultComponent, Attach = RotateCompX)
	UFauxPhysicsAxisRotateComponent RotateCompY;
	default RotateCompY.LocalRotationAxis = FVector::RightVector;
	default RotateCompY.Friction = 4.0;
//	default RotateCompY.SpringStrength = 50.0;
*/
	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	UFauxPhysicsWeightComponent WeightComp;
	default WeightComp.RelativeLocation = FVector::UpVector * -400.0;
	default	WeightComp.MassScale = 0.2;

	UPROPERTY(DefaultComponent, Attach = ConeRotateComp)
	USkylineHighwayFloatingComponent FloatingComp;

	UPROPERTY(DefaultComponent)
	UFauxPhysicsPlayerWeightComponent PlayerWeightComp;
	default PlayerWeightComp.PlayerForce = 100.0;
	default PlayerWeightComp.PlayerImpulseScale = 0.05;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 15000.0;
	default DisableComp.bActorIsVisualOnly = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Wait one tick
		Timer::SetTimer(this, n"LateBeginPlay", 0.001);
	}

	UFUNCTION()
	private void LateBeginPlay()
	{
		// I hate waiting one tick, but this allows for other actors to move this actor, without that being
		// applied on the Weight component on initialize
		TranslateCompZ.ResetInternalState();
		ConeRotateComp.ResetInternalState();
		WeightComp.ResetInternalState();
	}
};