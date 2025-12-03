UCLASS(Abstract)
class ADentistDoubleCannonTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	private USceneComponent MioTarget;

	UPROPERTY(DefaultComponent)
	private USceneComponent ZoeTarget;

#if EDITOR
	UPROPERTY(DefaultComponent)
	private UEditorBillboardComponent EditorIcon;
	default EditorIcon.WorldScale3D = FVector(1);

	UPROPERTY(DefaultComponent, Attach = MioTarget)
	private UDentistToothMeshPreviewComponent MioPreview;

	UPROPERTY(DefaultComponent, Attach = ZoeTarget)
	private UDentistToothMeshPreviewComponent ZoePreview;

	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		TArray<ADentistDoubleCannon> Cannons = GetTargetingCannons();
		for(auto Cannon : Cannons)
			Cannon.UpdateAiming();

		MioPreview.SetRelativeTransform(FTransform::Identity);
		ZoePreview.SetRelativeTransform(FTransform::Identity);
	}

	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		TArray<ADentistDoubleCannon> Cannons = GetTargetingCannons();
		for(auto Cannon : Cannons)
			Dentist::DoubleCannon::VisualizeDoubleCannon(Cannon);
	}

	private TArray<ADentistDoubleCannon> GetTargetingCannons() const
	{
		TArray<ADentistDoubleCannon> Cannons;

		TArray<ADentistDoubleCannon> Actors = Editor::GetAllEditorWorldActorsOfClass(ADentistDoubleCannon);
		for(AActor Actor : Actors)
		{
			auto Cannon = Cast<ADentistDoubleCannon>(Actor);
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
		TArray<ADentistDoubleCannon> Cannons = GetTargetingCannons();
		Editor::SelectActors(Cannons, true);
	}
#endif

	USceneComponent GetTargetForPlayer(EHazePlayer Player) const
	{
		switch(Player)
		{
			case EHazePlayer::Mio:
				return MioTarget;

			case EHazePlayer::Zoe:
				return ZoeTarget;
		}
	}

	FVector GetTargetLocationForPlayer(EHazePlayer Player, bool bCenter) const
	{
		FTransform WorldTransform = GetTargetForPlayer(Player).WorldTransform;

		if(bCenter)
			return WorldTransform.TransformPositionNoScale(FVector(0, 0, Dentist::CollisionRadius));
		else
			return WorldTransform.Location;
	}
};