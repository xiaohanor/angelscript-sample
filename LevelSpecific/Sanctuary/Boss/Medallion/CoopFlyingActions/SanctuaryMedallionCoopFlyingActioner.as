
class ASanctuaryMedallionCoopFlyingActioner : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UHazeActionQueueComponent ActionQueueComp;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;

	ASanctuaryBossMedallionHydraReferences Refs;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		TListedActors<ASanctuaryBossMedallionHydraReferences> Refss;
		if (Refss.Num() > 0)
		{
			Refs = Refss.Single;
			Refs.MedallionBossPlane2D.OnSplineEvent.AddUFunction(this, n"CoopFlyingSplineEvent");
			SetActorTickEnabled(false);
		}
	}

	UFUNCTION()
	private void CoopFlyingSplineEvent(ESanctuaryMedallionSplineEventType EventType, FSanctuaryMedallionSplineEventData EventData)
	{
	}
};