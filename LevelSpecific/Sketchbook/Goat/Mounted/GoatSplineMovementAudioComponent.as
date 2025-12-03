struct FGoatSplineAudioEventData
{
	UPROPERTY(EditInstanceOnly, Meta = (UIMin = 0.0, ClampMin = 0.0, UIMax = 1.0, ClampMax = 1.0))
	float TriggerFraction = 0.0;

	UPROPERTY(EditInstanceOnly)
	UHazeAudioEvent Event;

	UPROPERTY(EditInstanceOnly)
	TPerPlayer<bool> TriggerPlayers;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerForwards = true;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerBackwards = true;

	UPROPERTY(EditInstanceOnly)
	bool bTriggerOnce = true;

	UPROPERTY(EditInstanceOnly, Meta = (EditCondition = bTriggerOnce, EditConditionHides))
	bool bTriggerOncePerPlayer = true;

	TPerPlayer<bool> HasTriggeredPlayers;

	FGoatSplineAudioEventData()
	{
		TriggerPlayers[0] = true;
		TriggerPlayers[1] = true;
	}
}

class UGoatSplineMovementAudioComponent : UActorComponent
{
	#if EDITOR
	UPROPERTY(EditInstanceOnly, Category = "Audio", Meta = (UIMin = 0.0, ClampMin = 0.0, UIMax = 1.0, ClampMax = 1.0))
	float PreviewFraction = 0.0;

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		ASketchbookGoatSpline GoatSpline = Cast<ASketchbookGoatSpline>(Owner);
		if(GoatSpline == nullptr)
			return;	

		float SplineDistance = GoatSpline.Spline.SplineLength * PreviewFraction;
		Debug::DrawDebugPoint(GoatSpline.Spline.GetSplinePositionAtSplineDistance(SplineDistance).WorldLocation, 25.f, FLinearColor::Yellow, bDrawInForeground = true);
	}
	#endif

	UPROPERTY(EditInstanceOnly, Category = "Audio", Meta = (TitleProperty = Event))
	TArray<FGoatSplineAudioEventData> SplineEventData;

	ASketchbookGoatSpline Spline;
	private TPerPlayer<float> LastPlayerSplineAlpha;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Spline = Cast<ASketchbookGoatSpline>(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		for(auto& EventData : SplineEventData)
		{
			if(EventData.Event == nullptr)
				continue;
		
			for(auto Goat : Sketchbook::Goat::GetGoats())
			{
				if(Goat.MountedPlayer == nullptr)
					continue;

				if(EventData.bTriggerOnce)
				{
					if(!EventData.bTriggerOncePerPlayer
					&& (EventData.TriggerPlayers[Goat.MountedPlayer] || EventData.TriggerPlayers[Goat.MountedPlayer.OtherPlayer]))
						continue;
					
					if(EventData.bTriggerOncePerPlayer
					&& EventData.HasTriggeredPlayers[Goat.MountedPlayer])
						continue;
				}

				if(!EventData.TriggerPlayers[Goat.MountedPlayer])
					continue;

				UHazeSplineComponent GoatSpline = Goat.GetGoatSplineMoveComp().GetCurrentSpline();
				if(GoatSpline != Spline.Spline)
					continue;		

				const float SplineAlpha = GoatSpline.GetClosestSplineDistanceToWorldLocation(Goat.ActorLocation) / GoatSpline.SplineLength;
				bool bCanPlayEvent = false;

				if(EventData.bTriggerForwards
				&& LastPlayerSplineAlpha[Goat.MountedPlayer] < SplineAlpha
				&& (LastPlayerSplineAlpha[Goat.MountedPlayer] < EventData.TriggerFraction && SplineAlpha >= EventData.TriggerFraction))
					bCanPlayEvent = true;

				else if(EventData.bTriggerBackwards
				&& LastPlayerSplineAlpha[Goat.MountedPlayer] > SplineAlpha
				&& (LastPlayerSplineAlpha[Goat.MountedPlayer] > EventData.TriggerFraction && SplineAlpha <= EventData.TriggerFraction))
					bCanPlayEvent = true;

				if(bCanPlayEvent)
				{
					Audio::PostEventOnPlayer(Goat.MountedPlayer, EventData.Event);
					EventData.HasTriggeredPlayers[Goat.MountedPlayer] = true;
				}

				LastPlayerSplineAlpha[Goat.MountedPlayer] = SplineAlpha;
			}			
		}
	}

}