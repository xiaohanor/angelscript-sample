event void FOnSanctuarySnakeReachedSplineEnd();

class USanctuarySnakeSplineFollowComponent : UActorComponent
{
	UPROPERTY()
	bool bFollowSpline = false;

	UPROPERTY()
	float DistanceOnSpline = 0.0;

	float AddedDistance = 200.0;

	USanctuarySnakeSettings Settings;

	UPROPERTY()
	FTransform Transform;

	UPROPERTY()
	UHazeSplineComponent Spline;

	UPROPERTY()
	USanctuarySnakeSplineEffectComponent SplineEffectComponent;

	TArray<int> ActiveEffects;

	UPROPERTY()
	FOnSanctuarySnakeReachedSplineEnd OnSplineEndReached;

	AHazeActor Snake;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Snake = Cast<AHazeActor>(Owner);

		Settings = USanctuarySnakeSettings::GetSettings(Snake);
	}

	UFUNCTION()
	void SetSplineToFollow(UObject SplineToFollow)
	{
		Spline = GetSplineComponent(SplineToFollow);
		if (Spline == nullptr)
			return;

		SplineEffectComponent = USanctuarySnakeSplineEffectComponent::Get(Spline.Owner);

		DistanceOnSpline = 0.0;
	}

	UFUNCTION()
	UHazeSplineComponent GetSplineComponent(UObject SplineToFollow)
	{
		auto Actor = Cast<AActor>(SplineToFollow);
		if (Actor != nullptr)
		{
			auto SplineComponent = UHazeSplineComponent::Get(Actor);
			if (SplineComponent != nullptr)
				return SplineComponent;
		}
		
		auto SplineComponent = Cast<UHazeSplineComponent>(SplineToFollow);
		if (SplineComponent != nullptr)
			return SplineComponent;

		return nullptr;
	}	

	UFUNCTION()
	void Move(float Distance)
	{
		if (Spline == nullptr)
			return;

		DistanceOnSpline += Distance;

		Print("DistanceOnSpline: " + DistanceOnSpline, 0.0, FLinearColor::Green);

		float SplineLength = Spline.SplineLength;

		DistanceOnSpline = Math::Clamp(DistanceOnSpline, 0.0, SplineLength);

		// Handle Spline Effects
		if (SplineEffectComponent != nullptr)
		{
			Print("SplineEffect", 0.0, FLinearColor::Green);

			if (DistanceOnSpline >= SplineLength)
			{
				USanctuarySnakeEventHandler::Trigger_ClearEffects(Snake);		
				ActiveEffects.Reset();		
			/*
				for (auto Effect : SplineEffectComponent.Effects)
					Effect.bIsActive = false;
			*/
			}

			for (int i = 0; i < SplineEffectComponent.Effects.Num(); i++)
			{
				auto& Effects =  SplineEffectComponent.Effects;

	//			if (DistanceOnSpline + AddedDistance > Effects[i].Distance && DistanceOnSpline - Settings.StartLength < Effects[i].Distance && !Effects[i].bIsActive)
				if (DistanceOnSpline + AddedDistance > Effects[i].Distance && DistanceOnSpline - Settings.StartLength < Effects[i].Distance && !ActiveEffects.Contains(i))
				{
					ActiveEffects.Add(i);
				//	Effects[i].bIsActive = true;

					FTransform EffectTransform = SplineEffectComponent.GetTransformFromKey(Spline, Effects[i].Key);

					FSanctuarySnakeEffectData EffectData;
					EffectData.Key = i;
					EffectData.Component = Spline;
					EffectData.Transform = EffectTransform;

					if (Effects[i].bIsExit)
						USanctuarySnakeEventHandler::Trigger_BurrowExitStart(Snake, EffectData);
					else
						USanctuarySnakeEventHandler::Trigger_BurrowEntryStart(Snake, EffectData);

				}
				if (DistanceOnSpline - Settings.StartLength > Effects[i].Distance && ActiveEffects.Contains(i))
				{
					ActiveEffects.Remove(i);
			
				//	Effects[i].bIsActive = false;

					FTransform EffectTransform = SplineEffectComponent.GetTransformFromKey(Spline, Effects[i].Key);

					FSanctuarySnakeEffectData EffectData;
					EffectData.Key = i;
					EffectData.Component = Spline;
					EffectData.Transform = EffectTransform;
				
					if (Effects[i].bIsExit)
						USanctuarySnakeEventHandler::Trigger_BurrowExitEnd(Snake, EffectData);
					else
						USanctuarySnakeEventHandler::Trigger_BurrowEntryEnd(Snake, EffectData);
				}
			}
		}

		Transform = Spline.GetWorldTransformAtSplineDistance(DistanceOnSpline);

		if (DistanceOnSpline >= SplineLength)
		{
			bFollowSpline = false;
			Spline = nullptr;
			OnSplineEndReached.Broadcast();
		}
	}
}