class AStormFallCustomMoveObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent EndLoc;

	UPROPERTY(DefaultComponent, Attach = EndLoc)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(15.0));

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere)
	float Speed = 5000.0;
	float StartSpeed;

	UPROPERTY(EditAnywhere)
	float SlowDownRange = 4000.0;

	bool bStoppedMoving;

	float TotalSize;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		StartSpeed = Speed;
		TotalSize = (MeshRoot.RelativeLocation - EndLoc.RelativeLocation).Size();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		MeshRoot.RelativeLocation = Math::VInterpConstantTo(MeshRoot.RelativeLocation, EndLoc.RelativeLocation, DeltaSeconds, Speed);
		float Alpha = (MeshRoot.RelativeLocation - EndLoc.RelativeLocation).Size() / TotalSize;
		Alpha = 1 - Alpha;
		UStormFallCustomMoveObjectEffectHandler::Trigger_OnCustomObjectUpdateMoveAlpha(this, FStormFallCustomMoveObjectMoveAlphaParams(Alpha));

		if ((MeshRoot.RelativeLocation - EndLoc.RelativeLocation).Size() < SlowDownRange)
		{
			Speed = Math::FInterpConstantTo(Speed, StartSpeed / 8.0, DeltaSeconds, StartSpeed);
		}

		if ((MeshRoot.RelativeLocation - EndLoc.RelativeLocation).Size() < 50.0 && !bStoppedMoving)
		{
			bStoppedMoving = true;
			UStormFallCustomMoveObjectEffectHandler::Trigger_OnCustomObjectStoppedMoving(this);
		}
	}

	UFUNCTION()
	void ActivateObjectMovement()
	{
		SetActorTickEnabled(true);
		UStormFallCustomMoveObjectEffectHandler::Trigger_OnCustomObjectStartMoving(this);
	}
}