class UHydraAttackDummyComponent : UActorComponent
{
	//This component is here to fetch actor data for visualizer component
}

class UHydraAttackComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UHydraAttackDummyComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto DataActor = Cast<ASanctuaryBossHydraAttackDataActor>(Component.Owner);

		FVector X = DataActor.ActorLocation;
		FVector StartDirection = DataActor.StartTransform.Rotation.ForwardVector;
		FVector EndDirection = DataActor.EndTransform.Rotation.ForwardVector;

		DrawArrow(DataActor.StartTransform.Location + X + StartDirection * -100.0, DataActor.StartTransform.Location + X, FLinearColor::Green, 30.0, 10.0);
		DrawArrow(DataActor.EndTransform.Location + X + EndDirection * -100.0, DataActor.EndTransform.Location + X, FLinearColor::Red, 30.0, 10.0);

		DrawLine(DataActor.StartTransform.Location + X + StartDirection * 100.0, DataActor.StartTransform.Location + X + StartDirection * 5000.0, FLinearColor::LucBlue, 100.0);
		DrawLine(DataActor.EndTransform.Location + X + EndDirection * 100.0, DataActor.EndTransform.Location + X + EndDirection * 5000.0, FLinearColor::LucBlue, 100.0);
	}
}

class ASanctuaryBossHydraAttackDataActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHydraAttackDummyComponent DummyComp;

	FHazeRuntimeSpline HeadSpline;

	FHazeRuntimeSpline TargetSpline;

	UPROPERTY(EditInstanceOnly)
	ASanctuaryBossHydraHead HydraHeadActor;

	UPROPERTY(EditInstanceOnly, Meta = (MakeEditWidget))
	FTransform StartTransform;

	UPROPERTY(EditInstanceOnly, Meta = (MakeEditWidget))
	FTransform EndTransform;

	UPROPERTY(EditInstanceOnly)
	float AttackDuration = 5.0;

	UPROPERTY(EditInstanceOnly)
	float TelegraphDuration = 2.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FVector StartLocation = StartTransform.Location + ActorLocation;
		FQuat StartRotation = StartTransform.Rotation;
		FVector EndLocation = EndTransform.Location + ActorLocation;
		FQuat EndRotation = EndTransform.Rotation;

		HeadSpline.AddPoint(StartLocation);
		HeadSpline.AddPoint(EndLocation);
		TargetSpline.AddPoint(StartLocation + StartRotation.ForwardVector * 40000.0);
		TargetSpline.AddPoint(EndLocation + EndRotation.ForwardVector * 40000.0);
	}

	UFUNCTION(BlueprintCallable)
	void SendLaserData()
	{
		auto HydraBase = Hydra::GetHydraBase();
		if (HydraBase == nullptr)
			return;

		HydraBase.TriggerFireBreath(HeadSpline,
			TargetSpline,
			nullptr,
			AttackDuration,
			TelegraphDuration,
			-1.0,
			true,
			HydraHeadActor.Identifier
		);
	}
};