class ASkylineHighwayCombatGrappleManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent Visual;
	default Visual.WorldScale3D = FVector(5.0);
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<AActor> Points;
		GetAttachedActors(Points);
		for(AActor Point : Points)
		{
			AGrapplePoint GrapplePoint = Cast<AGrapplePoint>(Point);
			if(GrapplePoint != nullptr)
				GrapplePoint.GrapplePoint.Disable(this);
		}
	}

	UFUNCTION(BlueprintCallable)
	void EnableAll()
	{
		TArray<AActor> Points;
		GetAttachedActors(Points);
		for(AActor Point : Points)
		{
			AGrapplePoint GrapplePoint = Cast<AGrapplePoint>(Point);
			if(GrapplePoint != nullptr)
				GrapplePoint.GrapplePoint.Enable(this);
		}
	}
}