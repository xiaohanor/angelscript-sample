UCLASS(Abstract)
class ASeaWeedCover : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SeaweedParent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeMovablePlayerTriggerComponent SafeZone;

	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedAlpha;
	default SyncedAlpha.SyncRate = EHazeCrumbSyncRate::PlayerSynced;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 10000;

	UPROPERTY(EditAnywhere)
	AEvergreenLifeManager Manager;

	UPROPERTY(EditAnywhere)
	bool bFlipped = false;

	UPROPERTY(EditAnywhere)
	bool bHorizontal = false;

	UPROPERTY(EditAnywhere)
	float MinAlpha = 0.3;

	UPROPERTY(EditAnywhere)
	float MinAlphaSafeZone = -0.5;

	UPROPERTY(EditAnywhere)
	bool bDebugSafeZone = true;

	TArray<UStaticMeshComponent> SeaweedComponents;
	TArray<FVector> SeaweedComponentsStartScale;
	TArray<float> SeaweedComponentsRandom;

	float SeaweedInterpedAlpha = 0.0;
	float SafeZoneHeightExtent;

	const float Speed = 0.8;
	
#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnActorModifiedInEditor()
	{
		SafeZone.RelativeLocation = FVector(SafeZone.RelativeLocation.X, SafeZone.RelativeLocation.Y, SafeZone.Shape.BoxExtents.Z);
	}
#endif

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		if (HasControl())
			SyncedAlpha.Value = 0;

		SeaweedParent.GetChildrenComponentsByClass(UStaticMeshComponent, true, SeaweedComponents);
		
		for(UStaticMeshComponent Mesh : SeaweedComponents)
		{
			SeaweedComponentsStartScale.Add(Mesh.RelativeScale3D);
			SeaweedComponentsRandom.Add(Math::RandRange(1, 1.1));
		}

		SafeZone.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
		SafeZone.OnPlayerLeave.AddUFunction(this, n"OnPlayerLeave");

		devCheck(SafeZone.Shape.Type == EHazeShapeType::Box, "Seaweed Cover has safe zone with different shape than box, this is not currently supported!");
		SafeZoneHeightExtent = SafeZone.Shape.BoxExtents.Z;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(HasControl())
		{
			float Input = (bHorizontal ? Manager.LifeComp.RawHorizontalInput : Manager.LifeComp.RawVerticalInput) * (bFlipped ? -1.0 : 1.0);
			
			SyncedAlpha.Value += Speed * DeltaTime * Input;
			SyncedAlpha.Value = Math::Saturate(SyncedAlpha.Value);
		}

		SeaweedInterpedAlpha = Math::Lerp(SeaweedInterpedAlpha, SyncedAlpha.Value, DeltaTime * 8.0);
		
		float ActualSeaweedAlpha = Math::Lerp(MinAlpha, 1, SeaweedInterpedAlpha);

		UpdateSeaweedComponents(ActualSeaweedAlpha);

		float ZoneAlpha = Math::Lerp(MinAlphaSafeZone, 0.85, SeaweedInterpedAlpha);
		float CurrentSafeZoneHeightExtents = SafeZoneHeightExtent * ZoneAlpha;
		SafeZone.ChangeShape(FHazeShapeSettings::MakeBox(FVector(SafeZone.Shape.BoxExtents.X, SafeZone.Shape.BoxExtents.Y, CurrentSafeZoneHeightExtents)));
		SafeZone.RelativeLocation = FVector(SafeZone.RelativeLocation.X, SafeZone.RelativeLocation.Y, CurrentSafeZoneHeightExtents);

#if EDITOR
		if(bDebugSafeZone)
			Debug::DrawDebugBox(SafeZone.WorldLocation, SafeZone.Shape.BoxExtents, SafeZone.WorldRotation, FLinearColor::Red, 5.0);
#endif
	}

	UFUNCTION()
	private void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		UGentlemanComponent GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		GentlemanComp.SetInvalidTarget(this);
	}

	UFUNCTION()
	private void OnPlayerLeave(AHazePlayerCharacter Player)
	{
		UGentlemanComponent GentlemanComp = UGentlemanComponent::GetOrCreate(Player);
		GentlemanComp.ClearInvalidTarget(this);
	}

	void UpdateSeaweedComponents(float Alpha)
	{
		for (int i = 0; i < SeaweedComponents.Num(); i++)
		{
			UStaticMeshComponent SeaweedComponent = SeaweedComponents[i];
			
			SeaweedComponent.SetVectorParameterValueOnMaterials(n"EmissiveTint", FVector(0.750256, 1.0, 0.103049) * Math::Pow(Alpha, 10));
			SeaweedComponent.SetScalarParameterValueOnMaterials(n"SubsurfaceStrength", Math::Pow(Alpha, 5)*0.5);
			SeaweedComponent.SetScalarParameterValueOnMaterials(n"wind_FlutterStrength", 0.0);
			
			SeaweedComponent.SetRelativeScale3D(SeaweedComponentsStartScale[i] * Alpha * SeaweedComponentsRandom[i]);
		}
	}
}

#if EDITOR
class UTundraMovingVineToSeaWeedConverter : UScriptActorMenuExtension
{
	default SupportedClasses.Add(AMovingVine);
	default ExtensionPoint = n"ActorTypeTools";

	UFUNCTION(CallInEditor, DisplayName = "Convert MovingVine to SeaWeedCover", Meta = (EditorIcon = "Icons.ReplaceActor"))
	void ReplaceSelectedVinesWithSeaWeedCover(TSoftClassPtr<ASeaWeedCover> SeaWeedCoverClass)
	{
		TArray<AActor> SelectedActors = Editor::SelectedActors;
		for(AActor Actor : SelectedActors)
		{
			auto Vine = Cast<AMovingVine>(Actor);
			auto SeaWeedCover = SpawnActor(SeaWeedCoverClass.Get(), Vine.ActorLocation, Vine.ActorRotation);
			SeaWeedCover.bFlipped = Vine.bFlipped;
			SeaWeedCover.Manager = Vine.Manager;

			TArray<AActor> AttachedActors;
			TArray<AStaticMeshActor> AttachedSeaWeedActors;
			Vine.GetAttachedActors(AttachedActors, true, true);
			int Count = 0;
			FVector AverageLocation = FVector::ZeroVector;
			for(AActor AttachedActor : AttachedActors)
			{
				auto SeaweedActor = Cast<AStaticMeshActor>(AttachedActor);
				if(SeaweedActor == nullptr)
					continue;

				AverageLocation += SeaweedActor.ActorLocation;
				AttachedSeaWeedActors.Add(SeaweedActor);
				Count++;
			}

			UStaticMeshComponent ReferenceSeaweedComp = Cast<UStaticMeshComponent>(SeaWeedCover.SeaweedParent.GetChildComponent(0));

			AverageLocation /= Count;
			SeaWeedCover.ActorLocation = AverageLocation;
			if(SeaWeedCover.bFlipped)
				SeaWeedCover.ActorRotation = FRotator::MakeFromXZ(SeaWeedCover.ActorForwardVector, AttachedSeaWeedActors[0].ActorUpVector);
			bool bHasUsedReferenceSeaweedComp = false;

			FBox Box = FBox();
			for(int i = 0; i < AttachedSeaWeedActors.Num(); i++)
			{
				AStaticMeshActor SeaweedActor = AttachedSeaWeedActors[i];
				if(SeaweedActor.StaticMeshComponent.StaticMesh != ReferenceSeaweedComp.StaticMesh)
					continue;

				UStaticMeshComponent NewSeaWeedComp;
				if(!bHasUsedReferenceSeaweedComp)
				{
					NewSeaWeedComp = ReferenceSeaweedComp;
					bHasUsedReferenceSeaweedComp = true;
				}
				else
				{
					UActorComponent NewComp = Editor::AddInstanceComponentInEditor(SeaWeedCover, UStaticMeshComponent, FName(f"SeaWeed_{i}"));
					NewSeaWeedComp = Cast<UStaticMeshComponent>(NewComp);
				}

				NewSeaWeedComp.AttachToComponent(SeaWeedCover.SeaweedParent);
				NewSeaWeedComp.WorldTransform = SeaweedActor.ActorTransform;
				NewSeaWeedComp.StaticMesh = SeaweedActor.StaticMeshComponent.StaticMesh;
				NewSeaWeedComp.CollisionProfileName = SeaweedActor.StaticMeshComponent.CollisionProfileName;
				NewSeaWeedComp.SetMaterial(0, SeaweedActor.StaticMeshComponent.GetMaterial(0));
				Box += NewSeaWeedComp.GetBoundingBoxRelativeToOwner();
			}

			SeaWeedCover.SafeZone.ChangeShape(FHazeShapeSettings::MakeBox(Box.Extent));
			SeaWeedCover.SafeZone.RelativeLocation = Box.Center + FVector::DownVector * Box.Extent.Z;

			for(int i = AttachedActors.Num() - 1; i >= 0; i--)
			{
				UEditorActorSubsystem::Get().DestroyActor(AttachedActors[i]);
			}

			UEditorActorSubsystem::Get().DestroyActor(Vine);
			Editor::ToggleActorSelected(SeaWeedCover);
		}
	}
}
#endif