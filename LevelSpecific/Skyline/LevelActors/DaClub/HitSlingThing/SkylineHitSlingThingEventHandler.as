struct FSkylineHitSlingThingEventData
{
	UPROPERTY()
	ASkylineHitSlingThing BallActor;
}

struct FSkylineHitSlingThingEventImpactData
{
	UPROPERTY()
	ASkylineHitSlingThing BallActor;
	UPROPERTY()
	AActor ImpactActor;
	UPROPERTY()
	FVector ImpactLocation;
};

struct FSkylineHitSlingThingEventHitResponseComponentData
{
	UPROPERTY()
	AHazePlayerCharacter PlayerInstigator;
	UPROPERTY()
	ASkylineHitSlingThing BallActor;
	UPROPERTY()
	USkylineHitSlingThingResponseComponent ResponseCompenent;
	UPROPERTY()
	AActor ImpactActor;
	UPROPERTY()
	FVector ImpactLocation;
};


UCLASS(Abstract)
class USkylineHitSlingThingEventHandler : UHazeEffectEventHandler
{
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnBladeHit(FSkylineHitSlingThingEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipGrab(FSkylineHitSlingThingEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipReleased(FSkylineHitSlingThingEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnWhipThrown(FSkylineHitSlingThingEventData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnImpacted(FSkylineHitSlingThingEventImpactData EventData)
	{
	}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnResponseComponentHit(FSkylineHitSlingThingEventHitResponseComponentData EventData)
	{
	}
};