class USanctuaryBossSkydiveAttackActorVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuaryBossSkydiveAttackVisualizerComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto SkydiveAttack = Cast<ASanctuaryBossSkydiveAttackActor>(Component.Owner);

		if (SkydiveAttack.Spline == nullptr)
			return;

		FVector ClosestPointOnSpline = SkydiveAttack.Spline.GetClosestSplineWorldLocationToWorldLocation(SkydiveAttack.ActorLocation);

		DrawDashedLine(SkydiveAttack.ActorLocation, ClosestPointOnSpline, FLinearColor::Green, 10.0, 20.0);

		if (SkydiveAttack.AttackType == ESanctuaryBossHydraAttackType::Smash && SkydiveAttack.TargetActor != nullptr)
		{
			DrawDashedLine(SkydiveAttack.ActorLocation, SkydiveAttack.TargetActor.ActorLocation, FLinearColor::Red, 10.0, 20.0);	
		}

		if (SkydiveAttack.AttackType == ESanctuaryBossHydraAttackType::FireBreath)
		{
			if (SkydiveAttack.HeadSpline != nullptr)
				DrawDashedLine(SkydiveAttack.ActorLocation, SkydiveAttack.HeadSpline.ActorLocation, FLinearColor::Yellow, 10.0, 20.0);	

			if (SkydiveAttack.TargetSpline != nullptr)
				DrawDashedLine(SkydiveAttack.ActorLocation, SkydiveAttack.TargetSpline.ActorLocation, FLinearColor::Red, 10.0, 20.0);	
		}

		if (SkydiveAttack.HydraHead != nullptr)
		{
			DrawDashedLine(SkydiveAttack.ActorLocation, SkydiveAttack.HydraHead.HeadPivot.WorldLocation, FLinearColor::Blue, 10.0, 20.0);	
		}
	}
}

class USanctuaryBossSkydiveAttackVisualizerComponent : UActorComponent
{

}

class ASanctuaryBossSkydiveAttackActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSkydiveTriggerComponent SkydiveTriggerComp;

	UPROPERTY(DefaultComponent)
	USanctuaryBossSkydiveAttackVisualizerComponent VisualizerComp;

	UPROPERTY(EditAnywhere)
	ESanctuaryBossHydraAttackType AttackType = ESanctuaryBossHydraAttackType::Smash;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::FireBreath", EditConditionHides))
	ASplineActor HeadSpline;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::FireBreath", EditConditionHides))
	ASplineActor TargetSpline;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::Smash", EditConditionHides))
	AActor TargetActor;

	UPROPERTY(EditAnywhere)
	ASanctuaryBossHydraHead HydraHead;

	UPROPERTY(VisibleInstanceOnly)
	ESanctuaryBossHydraIdentifier Identifier = ESanctuaryBossHydraIdentifier::MAX;

	UPROPERTY(EditAnywhere)
	float TelegraphDuration = -1.0;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "AttackType == ESanctuaryBossHydraAttackType::FireBreath", EditConditionHides))
	float SweepDuration = -1.0;

	UHazeSplineComponent Spline;

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		if (HydraHead != nullptr)
			Identifier = HydraHead.Identifier;

		TArray<AActor> EditorSkydiveActors;
		EditorSkydiveActors = Editor::GetAllEditorWorldActorsOfClass(ASanctuaryBossSkydiveActor);
		if (EditorSkydiveActors.Num() > 0)
		{
			auto SkydiveActor = Cast<ASanctuaryBossSkydiveActor>(EditorSkydiveActors[0]);
			if (SkydiveActor != nullptr)
				SkydiveActor.UpdateAttackActors();
		}
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SkydiveTriggerComp.OnTriggered.AddUFunction(this, n"HandleTriggered");
	}

	UFUNCTION()
	private void HandleTriggered()
	{
		TriggerAttack();
	}

	void TriggerAttack()
	{
		auto Hydra = Hydra::GetHydraBase();

		USceneComponent PlatformComponent = nullptr;
		if (TargetActor != nullptr)
		{
			PlatformComponent = USanctuaryBossHydraPlatformComponent::Get(TargetActor);
			if (PlatformComponent == nullptr)
				PlatformComponent = TargetActor.RootComponent;
		}

		switch (AttackType)
		{
			case ESanctuaryBossHydraAttackType::FireBall:
				break;
			case ESanctuaryBossHydraAttackType::None:
				break;
			case ESanctuaryBossHydraAttackType::Smash:
			{
				if (TargetActor == nullptr)
					return;

				FVector TargetLocation = TargetActor.ActorLocation;

				auto TelegraphComponent = USanctuaryBossHydraTelegraphComponent::Get(TargetActor);
				if (PlatformComponent != nullptr)
					TargetLocation = PlatformComponent.WorldLocation;

				Hydra.TriggerSmash(
					TargetLocation,
					PlatformComponent,
					TelegraphComponent,
					TelegraphDuration,
					-1.0,
					Identifier
				);
				break;
			}
			case ESanctuaryBossHydraAttackType::FireBreath:
			{
				if (HeadSpline == nullptr || TargetSpline == nullptr)
					return;

				// TODO: Way too much data to send over network by default :^)
				float HeadSplineSampleStepSize = HeadSpline.Spline.SplineLength * 0.3;
				float TargetSplineSampleStepSize = TargetSpline.Spline.SplineLength * 0.3;

				Hydra.TriggerFireBreath(
					HeadSpline.Spline.BuildRuntimeSplineFromHazeSpline(HeadSplineSampleStepSize),
					TargetSpline.Spline.BuildRuntimeSplineFromHazeSpline(TargetSplineSampleStepSize),
					PlatformComponent,
					SweepDuration,
					TelegraphDuration,
					-1.0,
					false,
					Identifier
				);
				break;
			}		
		}
	}
};