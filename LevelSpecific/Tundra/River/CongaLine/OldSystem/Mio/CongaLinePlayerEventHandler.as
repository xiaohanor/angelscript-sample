struct FCongaLinePLayerOnDancerStartedEnteringEventData
{
	UPROPERTY()
	UCongaLineDancerComponent StartedEnteringDancer;
};

struct FCongaLinePLayerOnDancerEnteredEventData
{
	UPROPERTY()
	UCongaLineDancerComponent EnteredDancer;
};

struct FCongaLinePLayerOnLastDancerExitedEventData
{
	UPROPERTY()
	UCongaLineDancerComponent DispersedDancer;
};

struct FCongaLinePLayerOnSwitchedOutOfSnowMonkeyFormEventData
{
	UPROPERTY()
	TArray<UCongaLineDancerComponent> DispersedDancers;
};

struct FCongaLinePLayerOnHitWallEventData
{
	UPROPERTY()
	TArray<UCongaLineDancerComponent> DispersedDancers;
};

struct FCongaLinePLayerOnCollidedWithCongaLineEventData
{
	UPROPERTY()
	TArray<UCongaLineDancerComponent> DispersedDancers;
};

UCLASS(Abstract)
class UCongaLinePlayerEventHandler : UHazeEffectEventHandler
{
	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter Player;

	UPROPERTY(BlueprintReadOnly)
	UCongaLinePlayerComponent CongaLineComp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CongaLineComp = UCongaLinePlayerComponent::Get(Player);
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDancerStartedEntering(FCongaLinePLayerOnDancerStartedEnteringEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnDancerEntered(FCongaLinePLayerOnDancerEnteredEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnLastDancerExited(FCongaLinePLayerOnLastDancerExitedEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnSwitchedOutOfSnowMonkeyForm(FCongaLinePLayerOnSwitchedOutOfSnowMonkeyFormEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnHitWall(FCongaLinePLayerOnHitWallEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnCollidedWithCongaLine(FCongaLinePLayerOnCollidedWithCongaLineEventData EventData)
	{
	}
};