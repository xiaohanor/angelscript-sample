class AGiantsSkydiveMagnetPoint : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UGiantsSkydiveMagnetPointDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxDistanceForMagnet = 5000;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MagnetForceMax = 3000.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MagnetForceMin = 1000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerDistanceForMaxForce = 3000.0;
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PlayerDistanceForMinForce = 500.0;

	bool bDebugActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			UGiantsSkydiveMagnetPlayerComponent::Create(Player);
		}
		GiantsDevToggles::Giants.MakeVisible();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (GiantsDevToggles::DebugDrawMagnetPoint.IsEnabled())
		{
			ColorDebug::DrawTintedTransform(ActorLocation, ActorRotation, bDebugActive ? ColorDebug::White : ColorDebug::Gray, 500);
		}
	}
};

#if EDITOR
	class UGiantsSkydiveMagnetPointDummyComponent : UActorComponent {};

	class UGiantsSkydiveMagnetPointComponentVisualizer : UHazeScriptComponentVisualizer
	{
		default VisualizedClass = UGiantsSkydiveMagnetPointDummyComponent;

		UFUNCTION(BlueprintOverride)
		void VisualizeComponent(const UActorComponent Component)
		{
			auto Comp = Cast<UGiantsSkydiveMagnetPointDummyComponent>(Component);
			if(Comp == nullptr)
				return;
			
			auto Point = Cast<AGiantsSkydiveMagnetPoint>(Comp.Owner);
			if(Point == nullptr)
				return;
			
			DrawWireCylinder(Point.ActorLocation, FRotator::ZeroRotator, FLinearColor::Red, Point.MaxDistanceForMagnet, 4000, 64, 15, true);
			DrawWorldString("Max Distance", Point.ActorLocation + Point.ActorUpVector * (4000 + 100) + Point.ActorForwardVector * Point.MaxDistanceForMagnet, FLinearColor::Red);
			DrawWireSphere(Point.ActorLocation, 40, ColorDebug::Leaf, 2.0);
		}
	}
#endif