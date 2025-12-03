struct FSanctuarySnakeSplineEffectData
{
	UPROPERTY()
	float Key = 0.0;

	UPROPERTY()
	bool bIsExit = true;

	float Distance;

	UPROPERTY()
	UNiagaraSystem OneShotEffect;

	UPROPERTY()
	UNiagaraSystem LoopingEffect;

	FSanctuarySnakeSplineEffectData() {}
	FSanctuarySnakeSplineEffectData(float KeyValue)
	{
		Key = KeyValue;
	}
}

class USanctuarySnakeSplineEffectComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	TArray<FSanctuarySnakeSplineEffectData> Effects;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		auto Spline = UHazeSplineComponent::Get(Owner);
		if (Spline == nullptr)
			return;

		for (auto& Effect : Effects)
			Effect.Distance = GetDistanceFromKey(Spline, Effect.Key);
	}

	float GetDistanceFromKey(UHazeSplineComponent Spline, float Key)
	{
		float SplinePoint = 0.0;
		float Alpha = Math::Modf(Key, SplinePoint);
		float DistanceAtSplinePoint = Spline.GetSplineDistanceAtSplinePointIndex(int(SplinePoint));
		float CurveLength = Spline.GetSplineDistanceAtSplinePointIndex(int(SplinePoint) + 1) - DistanceAtSplinePoint;

		return DistanceAtSplinePoint + CurveLength * Alpha;
	}

	FTransform GetTransformFromKey(UHazeSplineComponent Spline, float Key)
	{
		return Spline.GetWorldTransformAtSplineDistance(GetDistanceFromKey(Spline, Key));
	}
}