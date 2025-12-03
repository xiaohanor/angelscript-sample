class ABabyDragonRaft : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USummitRaftRootComponent RootComp;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent RaftFront;

	UPROPERTY(DefaultComponent)
	UHazeOffsetComponent RaftBack;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mio;

	UPROPERTY(DefaultComponent, Attach = Mio, AttachSocket = "RightHand")
	UStaticMeshComponent MioOar;

	UPROPERTY(DefaultComponent, Attach = MioOar)
	UHazeOffsetComponent MioOarTrace;

	UPROPERTY(DefaultComponent, Attach = MioOar)
	UHazeOffsetComponent MioOarEnd;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Zoe;

	UPROPERTY(DefaultComponent, Attach = Zoe, AttachSocket = "LeftHand")
	UStaticMeshComponent ZoeOar;

	UPROPERTY(DefaultComponent, Attach = ZoeOar)
	UHazeOffsetComponent ZoeOarTrace;

	UPROPERTY(DefaultComponent, Attach = ZoeOar)
	UHazeOffsetComponent ZoeOarEnd;

	UPROPERTY(EditDefaultsOnly, BlueprintReadWrite)
	float RaftSpeed = 200;

	UPROPERTY(BlueprintReadWrite)
	bool bIsMoving = false; 

	bool bZoeOarSubmerged = false;
	bool bMioOarSubmerged = false;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FHazeTraceSettings OarTrace = Trace::InitChannel(ECollisionChannel::ECC_WorldStatic);

		OarTrace.IgnoreActor(this);
		FHitResult Hit = OarTrace.QueryTraceSingle(MioOarTrace.WorldLocation, MioOarEnd.WorldLocation);

		if(Hit.bBlockingHit
		&& Cast<ASummitRaftWaterStaticMeshActor>(Hit.Actor) != nullptr)
		{
			if(bMioOarSubmerged)
			{
				FBabyDragonRaftOarEventParams Params;
				Params.OarWaterEnterLocation = Hit.Location;
				UBabyDragonRaftEventHandler::Trigger_WhileOarSubmerged(this, Params);
			}
			else
			{
				FBabyDragonRaftOarEventParams Params;
				Params.OarWaterEnterLocation = Hit.Location;
				UBabyDragonRaftEventHandler::Trigger_OnOarEnterWater(this, Params);
				bMioOarSubmerged = true;
			}
		}
		else
		{
			bMioOarSubmerged = false;
		}

		Hit = OarTrace.QueryTraceSingle(ZoeOarTrace.WorldLocation, ZoeOarEnd.WorldLocation);

		if(Hit.bBlockingHit
		&& Cast<ASummitRaftWaterStaticMeshActor>(Hit.Actor) != nullptr)
		{
			if(bZoeOarSubmerged)
			{
				FBabyDragonRaftOarEventParams Params;
				Params.OarWaterEnterLocation = Hit.Location;
				UBabyDragonRaftEventHandler::Trigger_WhileOarSubmerged(this, Params);
			}
			else
			{
				FBabyDragonRaftOarEventParams Params;
				Params.OarWaterEnterLocation = Hit.Location;
				UBabyDragonRaftEventHandler::Trigger_OnOarEnterWater(this, Params);
				bZoeOarSubmerged = true;
			}
		}
		else
		{
			bZoeOarSubmerged = false;
		}

		// if(bMioOarSubmerged)
		// {
		// 	FPaddleOarEventParams Params;
		// 	FVector OarWaterIntersection = FVector(MioOarTrace.WorldLocation.X, MioOarTrace.WorldLocation.Y, 
		// 	RootComp.WorldLocation.Z + RootComp.WaterLevelOffset);
		// 	Params.OarWaterEnterLocation = OarWaterIntersection;
		// 	UPaddleRaftEventHandler::Trigger_WhileOarSubmerged(this, Params);
		// }
		// else if(!bMioOarSubmerged && 
		// 	MioOarTrace.WorldLocation.Z < (RootComp.WorldLocation.Z + RootComp.WaterLevelOffset))
		// {
		// 	FBabyDragonRaftOarEventParams Params;
		// 	Params.OarWaterEnterLocation = MioOarTrace.WorldLocation;
		// 	UBabyDragonRaftEventHandler::Trigger_OnOarEnterWater(this, Params);
		// 	bMioOarSubmerged = true;
		// }
		// else if(MioOarTrace.WorldLocation.Z > (RootComp.WorldLocation.Z + RootComp.WaterLevelOffset))
		// {
		// 	bMioOarSubmerged = false;
		// }

		// if(bZoeOarSubmerged)
		// {
		// 	FPaddleOarEventParams Params;
		// 	FVector OarWaterIntersection = FVector(ZoeOarTrace.WorldLocation.X, ZoeOarTrace.WorldLocation.Y, 
		// 	RootComp.WorldLocation.Z + RootComp.WaterLevelOffset);
		// 	Params.OarWaterEnterLocation = OarWaterIntersection;
		// 	UPaddleRaftEventHandler::Trigger_WhileOarSubmerged(this, Params);
		// }
		// if(!bZoeOarSubmerged &&
		// 	ZoeOarTrace.WorldLocation.Z < (RootComp.WorldLocation.Z + RootComp.WaterLevelOffset))
		// {
		// 	FBabyDragonRaftOarEventParams Params;
		// 	Params.OarWaterEnterLocation = ZoeOarTrace.WorldLocation;
		// 	UBabyDragonRaftEventHandler::Trigger_OnOarEnterWater(this, Params);
		// 	bZoeOarSubmerged = true;
		// }
		// else if (ZoeOarTrace.WorldLocation.Z > (RootComp.WorldLocation.Z + RootComp.WaterLevelOffset))
		// {
		// 	bZoeOarSubmerged = false;
		// }
	}
}