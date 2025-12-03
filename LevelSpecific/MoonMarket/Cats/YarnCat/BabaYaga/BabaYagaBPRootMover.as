event void FOnBabaYagaWokeUpInstance();

class ABabaYagaBPRootMover : AHazeActor
{
	UPROPERTY()
	FOnBabaYagaWokeUpInstance OnBabaYagaWokeUpInstance;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = Root)
	UBillboardComponent Visual;
	default Visual.SetWorldScale3D(FVector(6));
#endif

	UPROPERTY(DefaultComponent, Attach = Root)
	UPlayerInheritMovementComponent InheritMoveComp;
	default InheritMoveComp.SetWorldScale3D(FVector(22, 22, 30.0));
	default InheritMoveComp.SetRelativeLocation(FVector(500,0,3000.0));
	default InheritMoveComp.FollowPriority = EInstigatePriority::High;
	default InheritMoveComp.FollowBehavior = EMovementFollowComponentType::ReferenceFrame;

	UPROPERTY(DefaultComponent)
	UMoonMarketCatProgressComponent ProgressComp;

	ABabaYagaGeoRootMover GeoRootMover;

	FVector RandomDirection;
	float RandomDirectionHeight = 12.0;
	float DirectionChangeSize;
	float ChangeDirectionDuration = 1.5;
	float ChangeDirectionTime;
	FRotator TargetRot;

	float HeightBobAmount = 20.0;

	ABabaYagaLeg Leg;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProgressComp.OnProgressionActivated.AddUFunction(this, n"OnProgressionActivated");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (GeoRootMover == nullptr)
		{
			GeoRootMover = TListedActors<ABabaYagaGeoRootMover>().GetSingle();
			Leg = GeoRootMover.Leg;
			return;
		}

		SetActorLocationAndRotation(GeoRootMover.ActorLocation, GeoRootMover.ActorRotation);
	}

	UFUNCTION()
	private void OnProgressionActivated()
	{
		GeoRootMover = TListedActors<ABabaYagaGeoRootMover>().GetSingle();
		GeoRootMover.WakeUpInstant();
		OnBabaYagaWokeUpInstance.Broadcast();
	}

	UFUNCTION(DevFunction)
	void LegStandUp()
	{
		if(GeoRootMover.Leg.bIsStanding)
			return;

		Leg.Stand();
	}

	UFUNCTION(BlueprintCallable)
	void LightUp()
	{
		GeoRootMover.LightUp();
	}
};