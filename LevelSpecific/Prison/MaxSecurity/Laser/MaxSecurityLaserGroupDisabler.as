UCLASS(HideCategories = "Activation Tags")
class AMaxSecurityLaserGroupDisabler : AGroupedDisableActor
{
	UPROPERTY(EditInstanceOnly, Category = "Laser Group Disabling")
	float FindLasersRange = 1000;

#if EDITOR
	UPROPERTY(DefaultComponent, ShowOnActor)
	UMaxSecurityLaserGroupDisableComponent LaserGroupDisableComponent;
#endif

	#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		UpdateLinkedActors();
		CopyFindLaserRange();
	}
	
	UFUNCTION(CallInEditor)
	private void CopyFindLaserRange()
	{
		if(LaserGroupDisableComponent.FindLasersRange > 0)
		{
			// Copy this over so we can remove it from the component, and make that editor only
			FindLasersRange = LaserGroupDisableComponent.FindLasersRange;
			LaserGroupDisableComponent.FindLasersRange = -1;
		}
	}

	UFUNCTION(CallInEditor)
	private void UpdateLinkedActors()
	{
		DisableComp.AutoDisableLinkedActors.Reset();

		float DistanceSquared = Math::Square(FindLasersRange);

		auto AllLasers = Editor::GetAllEditorWorldActorsOfClass(AMaxSecurityLaser);
		for(auto It : AllLasers)
		{
			auto LaserActor = Cast<AMaxSecurityLaser>(It);
			if(ActorLocation.DistSquared(LaserActor.ActorLocation) < DistanceSquared)
				DisableComp.AutoDisableLinkedActors.Add(LaserActor);
		}
	}
	#endif

	UFUNCTION(CallInEditor)
	private void SelectUnDisableManagedLasers()
	{
	#if EDITOR
		TArray<AActor> AllLasers = Editor::GetAllEditorWorldActorsOfClass(AMaxSecurityLaser);
		TArray<AActor> AllDisablers = Editor::GetAllEditorWorldActorsOfClass(AMaxSecurityLaserGroupDisabler);

		for(auto Disabler : AllDisablers)
		{
			for(auto Laser : UDisableComponent::Get(Disabler).AutoDisableLinkedActors)
			{
				AllLasers.RemoveSingleSwap(Laser.Get());
			}
		}

		Print("Num Unmanaged Lasers: " + AllLasers.Num());
		Editor::SelectActors(AllLasers);
	#endif
	}

	UFUNCTION(CallInEditor)
	private void SelectMultiManaged()
	{
	#if EDITOR
		TArray<AMaxSecurityLaserGroupDisabler> AllDisablers = Editor::GetAllEditorWorldActorsOfClass(AMaxSecurityLaserGroupDisabler);

		TMap<AActor, int> LasersAndDisablersCount;

		for(auto Disabler : AllDisablers)
		{
			for(auto Laser : UDisableComponent::Get(Disabler).AutoDisableLinkedActors)
			{
				int Value;
				if(LasersAndDisablersCount.Find(Laser.Get(), Value))
				{
					LasersAndDisablersCount[Laser.Get()] = Value + 1;
				}
				else
				{
					LasersAndDisablersCount.Add(Laser.Get(), 1);
				}
			}
		}

		TArray<AActor> SelectedActors;

		for(auto LaserAndDisablerCount : LasersAndDisablersCount)
		{
			if(LaserAndDisablerCount.Value > 1)
				SelectedActors.Add(LaserAndDisablerCount.Key);
		}

		Print("Num multi-managed Lasers: " + SelectedActors.Num());
		Editor::SelectActors(SelectedActors);
	#endif
	}
}

UCLASS(NotBlueprintable)
class UMaxSecurityLaserGroupDisableComponent : UActorComponent
{
	UPROPERTY(VisibleInstanceOnly, Category = "Laser Group Disabling")
	float FindLasersRange = 1000;
};

class UMaxSecurityLaserGroupDisableComponentVisualizer : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UMaxSecurityLaserGroupDisableComponent;

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
		AMaxSecurityLaserGroupDisabler LaserGroupDisabler = Cast<AMaxSecurityLaserGroupDisabler>(Component.Owner);
		if (LaserGroupDisabler != nullptr)
		{
			const float Range = LaserGroupDisabler.FindLasersRange;
			const FVector Origin = LaserGroupDisabler.ActorLocation;

			DrawWireSphere(Origin, Range, FLinearColor::LucBlue, 2);
		}
	}
};