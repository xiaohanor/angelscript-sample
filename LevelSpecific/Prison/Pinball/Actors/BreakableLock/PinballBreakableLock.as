event void FPinballBreakableLockOnLockBroken(APinballBreakableLock Lock);

asset PinballBreakableLockLightCurve of UCurveFloat
{
	/*
	    ------------------------------------------------------------------
	10.0|           ·'''''''''''··.                                      |
	    |          ·               '·.                                   |
	    |         .                   '·.                                |
	    |                                ·.                              |
	    |        ·                         ·.                            |
	    |                                    ·.                          |
	    |       '                              ·.                        |
	    |      .                                 ·                       |
	    |                                         '·                     |
	    |     ·                                     '·                   |
	    |    .                                        '.                 |
	    |                                               '.               |
	    |   '                                             '·             |
	    |  ·                                                '·.          |
	    |·'                                                    '·.       |
	0.0 |                                                         '··....|
	    ------------------------------------------------------------------
	    0.0                                                            1.0
	*/
	AddAutoCurveKey(0.0, 1.0);
	AddCurveKeyTangent(0.2, 10.0, 0.0);
	AddCurveKeyTangent(0.3, 10.0, 0.0);
	AddAutoCurveKey(1.0, 0.0);
};

UCLASS(Abstract)
class APinballBreakableLock : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UHazeSphereCollisionComponent CollisionComp;

	UPROPERTY(DefaultComponent)
	UPinballLauncherComponent LauncherComp;
	default LauncherComp.bAllowLaunchFromBallSide = true;
	default LauncherComp.bStayLaunchedWhenMovingDown = true;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 3000;

	UPROPERTY(EditInstanceOnly)
	APinballGate GateActor;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float LaunchPower = 1000;

	UPROPERTY(EditInstanceOnly)
	APropLine PropLine;

	UPROPERTY(EditInstanceOnly)
	TArray<AHazeProp> HolderMeshActors;

	UPROPERTY(EditDefaultsOnly)
	FLinearColor EmissiveColor;

	UPROPERTY()
	FPinballBreakableLockOnLockBroken OnLockBroken;

	bool bBroken = false;
	float BreakTime = 0;
	TArray<UMeshComponent> PropLineMeshComponents;
	TArray<UMaterialInstanceDynamic> PropLineMIDs;
	TArray<UMaterialInstanceDynamic> HolderMeshMIDs;

	const float BreakDuration = 1.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LauncherComp.OnHitByBall.AddUFunction(this, n"OnHitByBall");

		GateActor.RegisterLock(this);

		PropLine.GetComponentsByClass(PropLineMeshComponents);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float TimeSinceBreak = Time::GetGameTimeSince(BreakTime);
		if(TimeSinceBreak > BreakDuration)
		{
			for(auto MID : PropLineMIDs)
				MID.SetVectorParameterValue(n"EmissiveTint", FLinearColor::Black);

			for(auto MID : HolderMeshMIDs)
			{
				MID.SetVectorParameterValue(n"BaseColor", FLinearColor::Black);
				MID.SetVectorParameterValue(n"EmissiveColor", FLinearColor::Black);
			}

			SetActorTickEnabled(false);
			return;
		}
		else
		{
			const float Alpha = TimeSinceBreak / BreakDuration;
			const float Value = PinballBreakableLockLightCurve.GetFloatValue(Alpha);
			const FLinearColor Color = EmissiveColor * Value;

			for(auto MID : PropLineMIDs)
				MID.SetVectorParameterValue(n"EmissiveTint", Color);

			for(auto MID : HolderMeshMIDs)
			{
				MID.SetVectorParameterValue(n"EmissiveColor", Color);
			}
		}
	}

	UFUNCTION(BlueprintCallable)
	void OnHitByBall(UPinballBallComponent BallComp, bool bIsProxy)
	{
		if(bBroken)
			return;

		OnLockBroken.Broadcast(this);
		UPinballBreakableLockEventHandler::Trigger_OnBroken(this);
		BP_OnBroken();

		for(auto MeshComp : PropLineMeshComponents)
		{
			auto MID = MeshComp.CreateDynamicMaterialInstance(0);
			MeshComp.SetMaterial(0, MID);
			PropLineMIDs.Add(MID);
		}

		for(auto HolderMeshActor : HolderMeshActors)
		{
			auto HolderMeshComp = UMeshComponent::Get(HolderMeshActor);
			auto MID = HolderMeshComp.CreateDynamicMaterialInstance(0);
			HolderMeshComp.SetMaterial(0, MID);
			HolderMeshMIDs.Add(MID);
		}

		bBroken = true;
		BreakTime = Time::GameTimeSeconds;
		SetActorTickEnabled(true);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnBroken() {}
}