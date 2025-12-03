event void FActorTriggerEvent(AHazeActor Actor);

/**
 * Trigger volume that tracks specific actors or actors of specific classes.
 */ 
UCLASS(HideCategories = "Collision Rendering Input Actor LOD Cooking Debug WorldPartition HLOD DataLayers", ComponentWrapperClass, Meta = (HighlightPlacement = "90"))
class AActorTrigger : AVolume
{
    default Shape::SetVolumeBrushColor(this, FLinearColor(0.5, 0.6, 0.1, 1.0));
	default BrushComponent.SetCollisionProfileName(n"Trigger");

	// Trigger enter events on any actor that inherits from one of the classes specified here
    UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Actor Trigger")
	TArray<TSubclassOf<AHazeActor>> ActorClasses;

	// Trigger enter events on the specific actors in the level this references
    UPROPERTY(BlueprintReadOnly, EditInstanceOnly, Category = "Actor Trigger")
	TArray<TSoftObjectPtr<AHazeActor>> SpecificActors;

	// Whether the trigger should ignore networking and only trigger locally
    UPROPERTY(BlueprintReadOnly, EditAnywhere, Category = "Actor Trigger", AdvancedDisplay)
	bool bTriggerLocally = false;

    UPROPERTY(Category = "Actor Trigger")
    FActorTriggerEvent OnActorEnter;

    UPROPERTY(Category = "Actor Trigger")
    FActorTriggerEvent OnActorLeave;

	private TArray<FInstigator> DisableInstigators;
	private TArray<AHazeActor> ActorsInsideTrigger;

    UFUNCTION(Category = "Actor Trigger")
    void EnableActorTrigger(FInstigator Instigator)
    {
		DisableInstigators.Remove(Instigator);
        UpdateAlreadyInsideActors();
    }

    UFUNCTION(Category = "Actor Trigger")
    void DisableActorTrigger(FInstigator Instigator)
    {
		DisableInstigators.AddUnique(Instigator);
        UpdateAlreadyInsideActors();
    }

	bool IsActorRelevant(AHazeActor Actor) const
	{
		for (auto SpecificActor : SpecificActors)
		{
			if (SpecificActor == Actor)
				return true;
		}

		for (auto SpecificActor : ActorClasses)
		{
			if (Actor.IsA(SpecificActor.Get()))
				return true;
		}

		return false;
	}

	UFUNCTION(BlueprintOverride)
	private void BeginPlay()
	{
	}

	// Manually update which actors are inside, we may have missed overlap events due to disable or streaming
	private void UpdateAlreadyInsideActors()
	{
		TArray<AActor> Overlaps;
		GetOverlappingActors(Overlaps, AHazeActor);

		for (auto Actor : Overlaps)
		{
			if (DisableInstigators.Num() != 0)
				ReceiveBeginOverlap(Actor);
			else
				ReceiveEndOverlap(Actor);
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorBeginOverlap(AActor OtherActor)
    {
		ReceiveBeginOverlap(OtherActor);
	}

    private void ReceiveBeginOverlap(AActor OtherActor)
    {
		AHazeActor HazeActor = Cast<AHazeActor>(OtherActor);
		if (HazeActor == nullptr)
			return;
		if (DisableInstigators.Num() != 0)
			return;
		if (!IsActorRelevant(HazeActor))
			return;
		if (!HazeActor.HasControl() && !bTriggerLocally)
			return;

		if (!ActorsInsideTrigger.Contains(HazeActor))
		{
			ActorsInsideTrigger.Add(HazeActor);
			if (bTriggerLocally)
				OnActorEnter.Broadcast(HazeActor);
			else
				CrumbActorEnter(HazeActor);
		}
	}

    UFUNCTION(BlueprintOverride)
    private void ActorEndOverlap(AActor OtherActor)
    {
		ReceiveEndOverlap(OtherActor);
	}

    private void ReceiveEndOverlap(AActor OtherActor)
    {
		AHazeActor HazeActor = Cast<AHazeActor>(OtherActor);
		if (HazeActor == nullptr)
			return;
		if (DisableInstigators.Num() != 0)
			return;
		if (!IsActorRelevant(HazeActor))
			return;
		if (!HazeActor.HasControl() && !bTriggerLocally)
			return;

		if (ActorsInsideTrigger.Contains(HazeActor))
		{
			ActorsInsideTrigger.Remove(HazeActor);
			if (bTriggerLocally)
				OnActorLeave.Broadcast(HazeActor);
			else
				CrumbActorLeave(HazeActor);
		}
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActorEnter(AHazeActor Actor)
	{
		OnActorEnter.Broadcast(Actor);
	}

	UFUNCTION(CrumbFunction)
	private void CrumbActorLeave(AHazeActor Actor)
	{
		OnActorLeave.Broadcast(Actor);
	}
}