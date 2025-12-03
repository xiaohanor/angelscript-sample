UCLASS(Abstract)
class UGravityBikeSplineEnemyTriggerComponent : UGravityBikeSplineDistanceTriggerComponent
{
	bool bImplementsExit = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		
		if(bUseEndExtent)
			check(bImplementsExit);
	}

	void OnEnemyEnter(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport)
	{
	}

	void OnEnemyExit(UGravityBikeSplineEnemyTriggerUserComponent TriggerUserComp, bool bIsTeleport)
	{
	}
};

#if EDITOR
class UGravityBikeSplineEnemyTriggerComponentVisualizer : UGravityBikeSplineDistanceTriggerComponentVisualizer
{
	default VisualizedClass = UGravityBikeSplineEnemyTriggerComponent;
	
	void Visualize(const UGravityBikeSplineDistanceTriggerComponent InTriggerComp) override
	{
		Super::Visualize(InTriggerComp);

		auto TriggerComp = Cast<UGravityBikeSplineEnemyTriggerComponent>(InTriggerComp);
		if(TriggerComp == nullptr)
			return;

        if(TriggerComp.bUseEndExtent && Editor::IsComponentSelected(TriggerComp))
        {
			ClearHitProxy();
			
			const float StartDistance = TriggerComp.GetStartDistance();
			const float EndDistance = TriggerComp.GetEndDistance();

            const float LineStep = 500;
            float Distance = StartDistance;
            FVector StartLocation = TriggerComp.GetSplineComp().GetWorldLocationAtSplineDistance(StartDistance);
            while(Distance < EndDistance)
            {
                Distance = Math::Min(Distance + LineStep, EndDistance);
                const FVector EndLocation = TriggerComp.GetSplineComp().GetWorldLocationAtSplineDistance(Distance);
				
                const float Alpha = Math::NormalizeToRange(Distance, StartDistance, EndDistance);
                FLinearColor Color = Math::Lerp(TriggerComp.StartColor, TriggerComp.EndColor, Alpha);
                DrawLine(StartLocation, EndLocation, Color, 20, true);
                StartLocation = EndLocation;
            }
        }
	}
};
#endif