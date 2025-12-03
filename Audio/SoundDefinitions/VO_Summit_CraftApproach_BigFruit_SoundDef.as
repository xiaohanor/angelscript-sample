
UCLASS(Abstract)
class UVO_Summit_CraftApproach_BigFruit_SoundDef : UHazeVOSoundDef
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void OnStartEating(){}

	UFUNCTION(BlueprintEvent)
	void OnObjectEaten(){}

	/* END OF AUTO-GENERATED CODE */

	UPROPERTY(EditInstanceOnly)
	APlayerLookAtTrigger LookAtTrigger;

	TArray<ASummitTeenDragonFruit> Fruits;
	bool bMioLineDone = false;

	float MinLookAtDistance = 500 * 500;
	float MinDot = 0.95;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		Fruits = TListedActors<ASummitTeenDragonFruit>().Array;
		bMioLineDone = PlayerOwner.IsZoe();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if (bMioLineDone)
			return;
		
		auto ViewForward = PlayerOwner.ViewRotation.ForwardVector;
		for (auto Fruit : Fruits)
		{
			#if TEST
			if (IsDebugging())
			{
				Debug::DrawDebugSphere(Fruit.ActorLocation, 500);
				auto Dot = ViewForward.DotProduct((Fruit.ActorLocation - PlayerOwner.ViewLocation).GetSafeNormal());
				Debug::DrawDebugString(Fruit.ActorLocation, f"Dot: {Dot}");
			}
			#endif

			float DistSqr = (Fruit.ActorLocation - PlayerOwner.FocusLocation).SizeSquared();
			if (DistSqr > MinLookAtDistance)
			{
				continue;
			}

			// Good enough.
			if (ViewForward.DotProduct((Fruit.ActorLocation - PlayerOwner.ViewLocation).GetSafeNormal()) > MinDot)
			{
				bMioLineDone = true;
				OnMioLookingAtFruit();
				break;
			}
		}
	}

	UFUNCTION(BlueprintEvent)
	void OnMioLookingAtFruit() {}
}