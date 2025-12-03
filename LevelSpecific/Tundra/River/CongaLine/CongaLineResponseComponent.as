event void FCongaLineResponseOnSuccessfulMeasure(); 

class UCongaLineResponseComponent : UActorComponent
{
	UPROPERTY()
	FCongaLineResponseOnSuccessfulMeasure OnSuccessfulMeasure;

	UPROPERTY(EditAnywhere)
	UOutlineDataAsset OutlineData;

	UPROPERTY(EditAnywhere)
	float Range = 500.0;

	UPROPERTY(EditAnywhere)
	bool bShouldOnlyActivateOnce = true;

	bool bIsInRange = false;
	bool bWasInRangeLastFrame = false;
	bool bIsActivated = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CongaLine::GetManager().OnMeasureEvent.AddUFunction(this, n"TryRespond");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bIsActivated && bShouldOnlyActivateOnce)
			return;

		bIsInRange = Game::GetMio().GetActorLocation().DistSquaredXY(Owner.ActorLocation) <= Range * Range;
		if(bIsInRange)
		{
			CongaLine::GetManager().MioInRangeOfInteractableFrame = Time::FrameNumber;
		}

		if(bWasInRangeLastFrame != bIsInRange)
		{
			if(bIsInRange)
				Outline::ApplyOutlineOnActor(Owner, Game::GetMio(), OutlineData, this, EInstigatePriority::Normal);
			else
				Outline::ClearOutlineOnActor(Owner, Game::GetMio(), this);

			bWasInRangeLastFrame = bIsInRange;
		}
	}

	UFUNCTION()
	void TryRespond(FCongaLineOnMeasureEventData EventData)
	{
		if(bIsActivated && bShouldOnlyActivateOnce)
			return;

		if(!bIsInRange)
			return;

		if(!EventData.SucceededAll || !EventData.bIsRestMeasure)
			return;

		bIsActivated = !bIsActivated;
		OnSuccessfulMeasure.Broadcast();

		if(bShouldOnlyActivateOnce)
		{
			Outline::ClearOutlineOnActor(Owner, Game::GetMio(), this);
		}
	}
};

class UCongaLineResponseComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UCongaLineResponseComponent;

	UFUNCTION(BlueprintOverride)
	void VisualizeComponent(const UActorComponent Component)
	{
		auto ResponseComp = Cast<UCongaLineResponseComponent>(Component);
		if(ResponseComp == nullptr)
			return;

		DrawWireSphere(ResponseComp.Owner.ActorLocation, ResponseComp.Range, FLinearColor::Green, 3, bScreenSpace = true);

	}
}