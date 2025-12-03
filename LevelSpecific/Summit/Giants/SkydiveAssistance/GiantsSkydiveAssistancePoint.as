class AGiantsSkydiveAssistancePoint : AActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent)
	UGiantsSkydiveAssistancePointDummyComponent DummyComp;
#endif

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 20000.0;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxDistanceForAssistance = 5000;

	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinDistanceForAssistance = 1000.0;

	/** Force which gets constantly applied towards the point
	 * Only while closer than the max distance and further away than the min distance
	 * Gets gradually lower while you get closer to the min distance
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float AssistanceForce = 2000.0;

	/** If under this speed towards the point, you will accelerate towards the point with the "MinSpeedAcceleration" */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinSpeedThreshold = 1000.0;

	/** If under the MinSpeedThreshold towards the point, you will accelerate with this amount per second */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MinSpeedAcceleration = 2000.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(auto Player : Game::Players)
		{
			UGiantsSkydiveAssistancePlayerComponent::Create(Player);
		}
	}
};

#if EDITOR
	class UGiantsSkydiveAssistancePointDummyComponent : UActorComponent {};

	class UGiantsSkydiveAssistancePointComponentVisualizer : UHazeScriptComponentVisualizer
	{
		default VisualizedClass = UGiantsSkydiveAssistancePointDummyComponent;

		UFUNCTION(BlueprintOverride)
		void VisualizeComponent(const UActorComponent Component)
		{
			auto Comp = Cast<UGiantsSkydiveAssistancePointDummyComponent>(Component);
			if(Comp == nullptr)
				return;
			
			auto Point = Cast<AGiantsSkydiveAssistancePoint>(Comp.Owner);
			if(Point == nullptr)
				return;
			
			DrawWireCylinder(Point.ActorLocation, FRotator::ZeroRotator, FLinearColor::Red, Point.MaxDistanceForAssistance, 4000, 64, 15, true);
			DrawWorldString("Max Distance", Point.ActorLocation + Point.ActorUpVector * (4000 + 100) + Point.ActorForwardVector * Point.MaxDistanceForAssistance, FLinearColor::Red);
			DrawWireCylinder(Point.ActorLocation, FRotator::ZeroRotator, FLinearColor::Green, Point.MinDistanceForAssistance, 1000, 64, 15, true);
			DrawWorldString("Min Distance", Point.ActorLocation + Point.ActorUpVector * (1000 + 100) + Point.ActorForwardVector * Point.MinDistanceForAssistance, FLinearColor::Green);
		
			DrawArrow(Point.ActorLocation, Point.ActorLocation + Point.ActorForwardVector * 500, FLinearColor::Red, 100, 10);
		}
	}
#endif