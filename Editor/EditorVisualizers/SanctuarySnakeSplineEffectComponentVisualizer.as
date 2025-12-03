class USanctuarySnakeSplineEffectComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = USanctuarySnakeSplineEffectComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(UActorComponent Component)
	{
		auto SanctuarySnakeSplineEffectComponent = Cast<USanctuarySnakeSplineEffectComponent>(Component);

		auto Spline = UHazeSplineComponent::Get(SanctuarySnakeSplineEffectComponent.Owner);
		if (Spline == nullptr)
			return;

		for (auto Effect : SanctuarySnakeSplineEffectComponent.Effects)
		{
			float Distance = SanctuarySnakeSplineEffectComponent.GetDistanceFromKey(Spline, Effect.Key);
			FTransform EffectTransform = Spline.GetWorldTransformAtSplineDistance(Distance);
			DrawCircle(EffectTransform.Location, 100.0, FLinearColor::Green, 10.0, EffectTransform.Rotation.ForwardVector);
			DrawArrow(EffectTransform.Location, EffectTransform.Location + EffectTransform.Rotation.ForwardVector * 100.0, FLinearColor::Green, 50.0, 10.0);
			DrawArrow(EffectTransform.Location - EffectTransform.Rotation.ForwardVector * 100.0, EffectTransform.Location, FLinearColor::Green, 50.0, 10.0);	
		}
	}
}