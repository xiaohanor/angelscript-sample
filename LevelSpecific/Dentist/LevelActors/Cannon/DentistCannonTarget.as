UCLASS(Abstract)
class ADentistCannonTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UEditorBillboardComponent EditorIcon;
	default EditorIcon.WorldScale3D = FVector(1);
#endif

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		TArray<ADentistCannon> Cannons = GetTargetingCannons();
		for(ADentistCannon Cannon : Cannons)
		{
			Cannon.UpdateAiming();
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		TArray<ADentistCannon> Cannons = GetTargetingCannons();
		for(ADentistCannon Cannon : Cannons)
			Dentist::Cannon::VisualizeCannon(Cannon);
	}

	private TArray<ADentistCannon> GetTargetingCannons() const
	{
		TArray<ADentistCannon> Cannons;

		TArray<ADentistCannon> Actors = Editor::GetAllEditorWorldActorsOfClass(ADentistCannon);
		for(AActor Actor : Actors)
		{
			auto Cannon = Cast<ADentistCannon>(Actor);
			if(Cannon == nullptr)
				continue;

			if(Cannon.AimAtTarget != this)
				continue;

			Cannons.Add(Cannon);
		}

		return Cannons;
	}

	UFUNCTION(CallInEditor, Category = "Cannon Target")
	void SelectTargetingCannons()
	{
		TArray<ADentistCannon> Cannons = GetTargetingCannons();
		Editor::SelectActors(Cannons, true);
	}
#endif
};